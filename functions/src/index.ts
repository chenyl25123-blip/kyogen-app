import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { Resend } from 'resend';

admin.initializeApp();
const db = admin.firestore();
const getResend = () => new Resend(process.env.RESEND_KEY ?? '');

// ── 日付ヘルパー (JST) ──────────────────────────────────
function getJSTDateString(offsetDays = 0): string {
  const jst = new Date(Date.now() + 9 * 60 * 60 * 1000);
  jst.setDate(jst.getDate() + offsetDays);
  const y = jst.getUTCFullYear();
  const m = String(jst.getUTCMonth() + 1).padStart(2, '0');
  const d = String(jst.getUTCDate()).padStart(2, '0');
  return `${y}-${m}-${d}`;
}


async function checkInExists(uid: string, date: string): Promise<boolean> {
  const doc = await db
    .collection('users').doc(uid)
    .collection('checkins').doc(date)
    .get();
  return doc.exists;
}

// ── ① 毎日定時チェック (JST 09:00) ─────────────────────
export const dailyCheckJob = functions
  .region('asia-northeast1')
  .pubsub
  .schedule('0 0 * * *')      // UTC 00:00 = JST 09:00
  .timeZone('UTC')
  .onRun(async (_ctx) => {
    const today      = getJSTDateString(0);
    const yesterday  = getJSTDateString(-1);
    const twoDaysAgo = getJSTDateString(-2);

    const usersSnap = await db.collection('users').get();

    await Promise.all(usersSnap.docs.map(async (userDoc) => {
      const { paused, fcmToken, lastNotifiedAt } = userDoc.data();
      const uid = userDoc.id;

      if (paused) return;
      if (await checkInExists(uid, today)) return;

      const yesterdayCI  = await checkInExists(uid, yesterday);
      const twoDaysAgoCI = await checkInExists(uid, twoDaysAgo);

      // ── warn: プッシュ通知 ────────────────────────────
      if (!yesterdayCI && twoDaysAgoCI) {
        if (fcmToken) {
          await admin.messaging().send({
            token: fcmToken,
            notification: {
              title: '昨日から確認がありません',
              body: '明日までに確認しないと、緊急連絡先へメールが届きます。',
            },
            apns: {
              payload: { aps: { sound: 'default', badge: 1 } },
            },
          });
        }
        return;
      }

      // ── alert: メール送信（エピソードにつき1回のみ） ────
      if (!yesterdayCI && !twoDaysAgoCI) {
        // lastNotifiedAt が null にリセットされるまで再送しない
        if (lastNotifiedAt) return;

        const contactDoc = await db
          .collection('users').doc(uid)
          .collection('contact').doc('main')
          .get();

        if (!contactDoc.exists) return;

        const contact  = contactDoc.data()!;
        const authUser = await admin.auth().getUser(uid);
        const userName = authUser.displayName || 'ユーザー';

        await getResend().emails.send({
          from: 'onboarding@resend.dev',
          to:   contact.email,
          subject: `${userName}さんの様子をご確認ください`,
          html: emergencyEmailHtml(userName),
        });

        await db.collection('users').doc(uid).update({
          lastNotifiedAt: admin.firestore.FieldValue.serverTimestamp(),
          emailSentCount: admin.firestore.FieldValue.increment(1),
        });
      }
    }));

    console.log(`dailyCheckJob completed for ${usersSnap.size} users`);
  });

// ── ② 签到时重置通知状态 ────────────────────────────────
// 用户重新签到后清空 lastNotifiedAt，使下次进入 alert 时可以再次发邮件
export const onCheckIn = functions
  .region('asia-northeast1')
  .firestore
  .document('users/{uid}/checkins/{date}')
  .onCreate(async (_snap, ctx) => {
    const uid = ctx.params.uid;
    await db.collection('users').doc(uid).update({
      lastNotifiedAt: null,
      emailSentCount: 0,
    });
  });

// ── ③ 連絡先登録時の確認メール ─────────────────────────
// メールアドレスが変わった場合のみ送信（無限ループ防止）
export const onContactSaved = functions
  .region('asia-northeast1')
  .firestore
  .document('users/{uid}/contact/main')
  .onWrite(async (change, ctx) => {
    if (!change.after.exists) return;

    const afterData  = change.after.data()!;

    // confirmedAt の更新だけの場合はスキップ（書き込みループ防止）
    if (change.before.exists) {
      const beforeData = change.before.data()!;
      if (beforeData.email === afterData.email) return;
    }

    const uid      = ctx.params.uid;
    const authUser = await admin.auth().getUser(uid);
    const userName = authUser.displayName || 'ユーザー';

    await getResend().emails.send({
      from:    'onboarding@resend.dev',
      to:      afterData.email,
      subject: `${userName}さんの緊急連絡先に登録されました`,
      html:    confirmEmailHtml(userName, afterData.name),
    });

    await change.after.ref.update({
      confirmedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

// ── ④ 新規ユーザー作成時の初期化 ─────────────────────
export const onUserCreated = functions
  .region('asia-northeast1')
  .auth
  .user()
  .onCreate(async (user) => {
    await db.collection('users').doc(user.uid).set({
      uid:            user.uid,
      createdAt:      admin.firestore.FieldValue.serverTimestamp(),
      fcmToken:       null,
      paused:         false,
      googleLinked:   user.providerData.some(p => p.providerId === 'google.com'),
      lastNotifiedAt: null,
      emailSentCount: 0,
    }, { merge: true });
  });

// ── ⑤ テストメール送信（Callable） ────────────────────
export const sendTestEmail = functions
  .region('asia-northeast1')
  .https.onCall(async (_data, ctx) => {
    if (!ctx.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'ログインが必要です');
    }

    const uid = ctx.auth.uid;
    const contactDoc = await db
      .collection('users').doc(uid)
      .collection('contact').doc('main')
      .get();

    if (!contactDoc.exists) {
      throw new functions.https.HttpsError('not-found', '連絡先が設定されていません');
    }

    const contact  = contactDoc.data()!;
    const authUser = await admin.auth().getUser(uid);
    const userName = authUser.displayName || 'ユーザー';

    await getResend().emails.send({
      from:    'onboarding@resend.dev',
      to:      contact.email,
      subject: `[テスト] ${userName}さんの様子をご確認ください`,
      html:    emergencyEmailHtml(userName),
    });

    return { success: true };
  });

// ── メールテンプレート ──────────────────────────────────
function emergencyEmailHtml(userName: string): string {
  return `
<!DOCTYPE html>
<html lang="ja">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"></head>
<body style="font-family:'Helvetica Neue',Arial,'Hiragino Kaku Gothic ProN',sans-serif;
             background:#f5f3f8;margin:0;padding:40px 20px">
  <div style="max-width:520px;margin:0 auto;background:#fff;border-radius:20px;
              border:1px solid #e2dded;overflow:hidden">
    <div style="background:#7ba8b5;padding:32px;text-align:center">
      <p style="color:#fff;font-size:13px;letter-spacing:.15em;margin:0 0 8px;
                text-transform:uppercase;opacity:.8">まもりんく</p>
      <h1 style="color:#fff;font-size:24px;font-weight:700;margin:0">
        様子のご確認のお願い
      </h1>
    </div>
    <div style="padding:32px">
      <p style="color:#3a3645;font-size:16px;line-height:1.8;margin:0 0 20px">
        <strong>${userName}</strong>さんから、3日以上ご連絡がありません。
      </p>
      <p style="color:#7a7390;font-size:14px;line-height:1.8;margin:0 0 24px">
        何らかの理由で確認できていない可能性がありますが、念のためご様子をご確認いただけますでしょうか。
      </p>
      <div style="background:#f5f3f8;border-radius:12px;padding:16px;margin-bottom:24px">
        <p style="color:#b0a8c4;font-size:11px;margin:0 0 4px;text-transform:uppercase;letter-spacing:.1em">このメールについて</p>
        <p style="color:#7a7390;font-size:13px;margin:0;line-height:1.6">
          このメールは「まもりんく」アプリの安否確認サービスにより自動送信されました。
          ${userName}さんが緊急連絡先としてあなたを登録しています。
        </p>
      </div>
    </div>
    <div style="padding:16px 32px 24px;border-top:1px solid #e2dded;text-align:center">
      <p style="color:#b0a8c4;font-size:11px;margin:0">
        このメールへの返信は届きません。
        配信停止をご希望の場合は <a href="mailto:unsubscribe@kyogen.app"
        style="color:#7ba8b5">こちら</a> へご連絡ください。
      </p>
    </div>
  </div>
</body>
</html>`;
}

function confirmEmailHtml(userName: string, contactName: string): string {
  return `
<!DOCTYPE html>
<html lang="ja">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"></head>
<body style="font-family:'Helvetica Neue',Arial,'Hiragino Kaku Gothic ProN',sans-serif;
             background:#f5f3f8;margin:0;padding:40px 20px">
  <div style="max-width:520px;margin:0 auto;background:#fff;border-radius:20px;
              border:1px solid #e2dded;overflow:hidden">
    <div style="background:#7ba8b5;padding:32px;text-align:center">
      <h1 style="color:#fff;font-size:22px;font-weight:700;margin:0">
        緊急連絡先への登録のお知らせ
      </h1>
    </div>
    <div style="padding:32px">
      <p style="color:#3a3645;font-size:16px;line-height:1.8;margin:0 0 16px">
        ${contactName} 様
      </p>
      <p style="color:#7a7390;font-size:14px;line-height:1.8;margin:0 0 16px">
        <strong>${userName}</strong>さんが、あなたを「まもりんく」アプリの
        緊急連絡先として登録しました。
      </p>
      <p style="color:#7a7390;font-size:14px;line-height:1.8;margin:0 0 24px">
        「まもりんく」は、毎日のチェックインで安否確認を行うアプリです。
        ${userName}さんが3日以上チェックインされない場合、あなたへ自動でご連絡が届きます。
      </p>
      <div style="background:#f5f3f8;border-radius:12px;padding:16px">
        <p style="color:#7a7390;font-size:13px;margin:0;line-height:1.6">
          このメールはご確認のみを目的としています。
          現時点では何も対応は必要ありません。
        </p>
      </div>
    </div>
    <div style="padding:16px 32px 24px;border-top:1px solid #e2dded;text-align:center">
      <p style="color:#b0a8c4;font-size:11px;margin:0">
        配信停止をご希望の場合は <a href="mailto:unsubscribe@kyogen.app"
        style="color:#7ba8b5">こちら</a> へご連絡ください。
      </p>
    </div>
  </div>
</body>
</html>`;
}
