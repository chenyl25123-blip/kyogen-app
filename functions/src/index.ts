import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import * as nodemailer from 'nodemailer';

admin.initializeApp();
const db = admin.firestore();

const getTransporter = () => nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.GMAIL_USER ?? '',
    pass: process.env.GMAIL_PASS ?? '',
  },
});

async function sendEmail(to: string, subject: string, html: string): Promise<void> {
  await getTransporter().sendMail({
    from: `"まもりんく" <${process.env.GMAIL_USER}>`,
    to,
    subject,
    html,
  });
}

// ── 日付ヘルパー (JST) ──────────────────────────────────
function getJSTDateString(offsetDays = 0): string {
  const jst = new Date(Date.now() + 9 * 60 * 60 * 1000);
  jst.setDate(jst.getDate() + offsetDays);
  const y = jst.getUTCFullYear();
  const m = String(jst.getUTCMonth() + 1).padStart(2, '0');
  const d = String(jst.getUTCDate()).padStart(2, '0');
  return `${y}-${m}-${d}`;
}


async function getUserName(uid: string): Promise<string> {
  const userDoc = await db.collection('users').doc(uid).get();
  const saved = userDoc.data()?.displayName;
  if (saved && saved.trim()) return saved.trim();
  const authUser = await admin.auth().getUser(uid);
  return authUser.displayName || authUser.email || 'ユーザー';
}

async function checkInExists(uid: string, date: string): Promise<boolean> {
  const doc = await db
    .collection('users').doc(uid)
    .collection('checkins').doc(date)
    .get();
  return doc.exists;
}

// ── ① 毎日定時チェック (JST 09:00) - 推送のみ ─────────────
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
      const { paused, fcmToken, createdAt } = userDoc.data();
      const uid = userDoc.id;

      if (paused) return;
      if (await checkInExists(uid, today)) return;

      // 登録から3日以内のユーザーはスキップ（新規登録直後の誤検知を防ぐ）
      if (createdAt) {
        const threeDaysAgo = new Date(Date.now() - 3 * 24 * 60 * 60 * 1000);
        if (createdAt.toDate() > threeDaysAgo) return;
      }

      const yesterdayCI  = await checkInExists(uid, yesterday);
      const twoDaysAgoCI = await checkInExists(uid, twoDaysAgo);

      // ── warn: プッシュ通知（昨日なし＋前日あり） ────────────
      if (!yesterdayCI && twoDaysAgoCI) {
        if (fcmToken) {
          await admin.messaging().send({
            token: fcmToken,
            notification: {
              title: '昨日から確認がありません',
              body: '今日中に確認いただくか、本日夜9時までに確認がない場合、緊急連絡先へメールが届きます。',
            },
            apns: {
              payload: { aps: { sound: 'default', badge: 1 } },
            },
          });
        }
      }
    }));

    console.log(`dailyCheckJob (push) completed for ${usersSnap.size} users`);
  });

// ── ① -2 毎日定時メール (JST 21:00) - メール送信のみ ──────
export const dailyEmailJob = functions
  .region('asia-northeast1')
  .pubsub
  .schedule('0 12 * * *')     // UTC 12:00 = JST 21:00
  .timeZone('UTC')
  .onRun(async (_ctx) => {
    const today      = getJSTDateString(0);
    const yesterday  = getJSTDateString(-1);
    const twoDaysAgo = getJSTDateString(-2);

    const usersSnap = await db.collection('users').get();

    await Promise.all(usersSnap.docs.map(async (userDoc) => {
      const { paused, lastNotifiedAt, createdAt } = userDoc.data();
      const uid = userDoc.id;

      if (paused) return;
      if (await checkInExists(uid, today)) return;

      // 登録から3日以内のユーザーはスキップ
      if (createdAt) {
        const threeDaysAgo = new Date(Date.now() - 3 * 24 * 60 * 60 * 1000);
        if (createdAt.toDate() > threeDaysAgo) return;
      }

      const yesterdayCI  = await checkInExists(uid, yesterday);
      const twoDaysAgoCI = await checkInExists(uid, twoDaysAgo);

      // ── alert: メール送信（昨日なし＋前日もなし＋未送信） ────
      if (!yesterdayCI && !twoDaysAgoCI) {
        // lastNotifiedAt が null にリセットされるまで再送しない
        if (lastNotifiedAt) return;

        const contactDoc = await db
          .collection('users').doc(uid)
          .collection('contact').doc('main')
          .get();

        if (!contactDoc.exists) return;

        const contact  = contactDoc.data()!;
        const userName = await getUserName(uid);

        await sendEmail(
          contact.email,
          `${userName}さんの様子をご確認ください`,
          emergencyEmailHtml(userName),
        );

        await db.collection('users').doc(uid).update({
          lastNotifiedAt: admin.firestore.FieldValue.serverTimestamp(),
          emailSentCount: admin.firestore.FieldValue.increment(1),
        });
      }
    }));

    console.log(`dailyEmailJob completed for ${usersSnap.size} users`);
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

// ── ③ 連絡先登録時の確認メール（Callable） ─────────────
// クライアントから明示的に呼び出して送信＆フィードバックを返す
export const sendContactConfirmEmail = functions
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
    const userName = await getUserName(uid);

    await sendEmail(
      contact.email,
      `${userName}さんの緊急連絡先に登録されました`,
      confirmEmailHtml(userName, contact.name),
    );

    await db.collection('users').doc(uid)
      .collection('contact').doc('main')
      .update({ confirmedAt: admin.firestore.FieldValue.serverTimestamp() });

    return { success: true };
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
    const userName = await getUserName(uid);

    await sendEmail(
      contact.email,
      `[テスト] ${userName}さんの様子をご確認ください`,
      emergencyEmailHtml(userName),
    );

    return { success: true };
  });

// ── ⑥ デバッグ：日付オフセットで dailyCheck を擬似実行 ──
// offsetDays=2 → 推送テスト（今日チェックイン済みなら twoDaysAgo に記録あり）
// offsetDays=3 → メールテスト（2日連続未確認を擬似）
export const debugRunDailyCheck = functions
  .region('asia-northeast1')
  .https.onCall(async (data, ctx) => {
    if (!ctx.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'ログインが必要です');
    }
    const uid = ctx.auth.uid;
    const offsetDays: number = typeof data?.offsetDays === 'number' ? data.offsetDays : 2;

    const simulatedToday = getJSTDateString(offsetDays);
    const yesterday      = getJSTDateString(offsetDays - 1);
    const twoDaysAgo     = getJSTDateString(offsetDays - 2);

    const userDoc = await db.collection('users').doc(uid).get();
    if (!userDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'ユーザーデータが見つかりません');
    }
    const { paused, fcmToken } = userDoc.data()!;

    if (paused) return { result: 'skipped', reason: 'paused' };
    if (await checkInExists(uid, simulatedToday)) {
      return { result: 'skipped', reason: 'checked_in_on_simulated_today', simulatedToday };
    }

    const yesterdayCI  = await checkInExists(uid, yesterday);
    const twoDaysAgoCI = await checkInExists(uid, twoDaysAgo);

    if (!yesterdayCI && twoDaysAgoCI) {
      if (!fcmToken) return { result: 'push_skipped', reason: 'no_fcm_token' };
      await admin.messaging().send({
        token: fcmToken,
        notification: {
          title: '[テスト] 昨日から確認がありません',
          body: '明日までに確認しないと、緊急連絡先へメールが届きます。',
        },
        apns: { payload: { aps: { sound: 'default', badge: 1 } } },
      });
      return { result: 'push_sent', simulatedToday };
    }

    if (!yesterdayCI && !twoDaysAgoCI) {
      const contactDoc = await db
        .collection('users').doc(uid)
        .collection('contact').doc('main')
        .get();
      if (!contactDoc.exists) return { result: 'email_skipped', reason: 'no_contact' };
      const contact  = contactDoc.data()!;
      const userName = await getUserName(uid);
      await sendEmail(
        contact.email,
        `[テスト] ${userName}さんの様子をご確認ください`,
        emergencyEmailHtml(userName),
      );
      return { result: 'email_sent', simulatedToday };
    }

    return { result: 'no_action', reason: 'checked_in_recently', yesterdayCI, twoDaysAgoCI, simulatedToday };
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
        <strong>${userName}</strong>さんが、2日連続でチェックインされていません。
      </p>
      <p style="color:#7a7390;font-size:14px;line-height:1.8;margin:0 0 24px">
        アプリへの毎日のチェックインが途切れています。念のため、お様子をご確認いただけますでしょうか。
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
        配信停止をご希望の場合は <a href="mailto:mamorinku.noreply@gmail.com"
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
        配信停止をご希望の場合は <a href="mailto:mamorinku.noreply@gmail.com"
        style="color:#7ba8b5">こちら</a> へご連絡ください。
      </p>
    </div>
  </div>
</body>
</html>`;
}
