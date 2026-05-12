import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/checkin_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _service = CheckInService();

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  bool _paused   = false;
  bool _reminder = true;
  bool _sound    = true;
  bool _loading  = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _loading = true);
    final doc = await FirebaseFirestore.instance
        .collection('users').doc(_uid).get();
    if (mounted) {
      setState(() {
        _paused  = (doc.data()?['paused'] ?? false) as bool;
        _loading = false;
      });
    }
  }

  Future<void> _togglePause(bool val) async {
    HapticFeedback.mediumImpact();
    setState(() => _paused = val);
    await _service.togglePause(val);
    _showSnack(val ? '機能を停止しまし�? : '機能を再開しまし�?🌿');
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.teal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _confirmReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bg2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('リセットの確�?,
            style: TextStyle(color: AppColors.text)),
        content: const Text(
          'すべてのデータが削除されます。\nこの操作は取り消せません�?,
          style: TextStyle(color: AppColors.text2, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセ�?,
                style: TextStyle(color: AppColors.text3)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('リセット',
                style: TextStyle(
                  color: AppColors.plum, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _service.resetAllData();
      if (mounted) {
        setState(() => _paused = false);
        _showSnack('データをリセットしました');
      }
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) _showSnack('ページを開けませんでした');
    }
  }

  void _openPrivacyPolicy() => _openUrl('https://kyogen.app/privacy');
  void _openTerms()         => _openUrl('https://kyogen.app/terms');

  void _openFeedbackSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _FeedbackSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                      child: Text('設定',
                          style: Theme.of(context).textTheme.titleLarge),
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverList(delegate: SliverChildListDelegate([

                      // ── 機能停止モー�?─────────────
                      const SectionLabel('モー�?, padding: EdgeInsets.only(bottom: 8)),
                      AppCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                              child: Row(
                                children: [
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('機能停止モー�?,
                                            style: TextStyle(
                                              fontSize: 14, fontWeight: FontWeight.w600,
                                              color: AppColors.text,
                                            )),
                                        SizedBox(height: 2),
                                        Text('旅行・入院中などに。通知・メール送信をすべて停止',
                                            style: TextStyle(
                                              fontSize: 11, color: AppColors.text3)),
                                      ],
                                    ),
                                  ),
                                  AppToggle(
                                    value: _paused,
                                    onChanged: _togglePause,
                                  ),
                                ],
                              ),
                            ),
                            if (_paused) ...[
                              const SizedBox(height: 12),
                              Container(
                                margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.peachDim,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: AppColors.peach.withOpacity(0.35)),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.info_outline,
                                        color: AppColors.peach, size: 16),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'この間に何があっても連絡先へのメールは送信されませ�?,
                                        style: TextStyle(
                                          fontSize: 11, color: AppColors.peach,
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ] else
                              const SizedBox(height: 12),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── 通知 ──────────────────────
                      const SectionLabel('通知', padding: EdgeInsets.only(bottom: 8)),
                      AppCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                              child: Row(
                                children: [
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('毎日のリマインダ�?,
                                            style: TextStyle(
                                              fontSize: 14, color: AppColors.text)),
                                        SizedBox(height: 2),
                                        Text('�?1時にプッシュ通知',
                                            style: TextStyle(
                                              fontSize: 11, color: AppColors.text3)),
                                      ],
                                    ),
                                  ),
                                  AppToggle(
                                    value: _reminder,
                                    onChanged: (val) {
                                      HapticFeedback.selectionClick();
                                      setState(() => _reminder = val);
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1, color: AppColors.border),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                              child: Row(
                                children: [
                                  const Expanded(
                                    child: Text('通知�?,
                                        style: TextStyle(
                                          fontSize: 14, color: AppColors.text)),
                                  ),
                                  AppToggle(
                                    value: _sound,
                                    onChanged: (val) {
                                      HapticFeedback.selectionClick();
                                      setState(() => _sound = val);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── サポート ──────────────────
                      const SectionLabel('サポート', padding: EdgeInsets.only(bottom: 8)),
                      AppCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            SettingsRow(
                              title: 'フィードバックを送る',
                              trailing: const Icon(Icons.chevron_right,
                                  size: 18, color: AppColors.text3),
                              onTap: _openFeedbackSheet,
                              showDivider: false,
                            ),
                            SettingsRow(
                              title: 'プライバシーポリシー',
                              trailing: const Icon(Icons.open_in_new,
                                  size: 16, color: AppColors.text3),
                              onTap: _openPrivacyPolicy,
                            ),
                            SettingsRow(
                              title: '利用規約',
                              trailing: const Icon(Icons.open_in_new,
                                  size: 16, color: AppColors.text3),
                              onTap: _openTerms,
                            ),
                            const SettingsRow(
                              title: 'バージョ�?,
                              trailing: Text('1.0.0',
                                  style: TextStyle(
                                    fontSize: 13, color: AppColors.text3)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ── リセット ──────────────────
                      GestureDetector(
                        onTap: _confirmReset,
                        child: const Center(
                          child: Text('すべてのデータをリセット',
                              style: TextStyle(
                                fontSize: 14, color: AppColors.plum,
                                fontWeight: FontWeight.w500,
                              )),
                        ),
                      ),
                      const SizedBox(height: 48),
                    ])),
                  ),
                ],
              ),
      ),
    );
  }
}

// ── フィードバックシート ───────────────────────────────
class _FeedbackSheet extends StatefulWidget {
  const _FeedbackSheet();

  @override
  State<_FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<_FeedbackSheet> {
  int _rating      = 0;
  String? _category;
  final _textCtrl  = TextEditingController();
  bool _submitted  = false;
  bool _submitting = false;

  static const _categories = ['💡 改善要望', '🐛 不具�?, '🎨 デザイン', '💬 その�?];
  static const _starLabels = ['', 'がっかり', 'もう少し', 'まあまあ', '良い�?, '最高！�?];

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('評価を選んでください'),
            backgroundColor: AppColors.peach),
      );
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _submitting = true);

    await FirebaseFirestore.instance.collection('feedback').add({
      'uid':       FirebaseAuth.instance.currentUser?.uid,
      'rating':    _rating,
      'category':  _category,
      'text':      _textCtrl.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (mounted) setState(() { _submitted = true; _submitting = false; });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9),
      margin: EdgeInsets.only(bottom: bottom),
      decoration: const BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border2,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 20),

            if (_submitted) ...[
              const SizedBox(height: 20),
              const Center(child: Text('🙏', style: TextStyle(fontSize: 48))),
              const SizedBox(height: 16),
              const Center(
                child: Text('ありがとうございます�?,
                    style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    )),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text('フィードバックを受け付けました。\n今後の改善に役立てます�?,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14, color: AppColors.text2, height: 1.5)),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: const Text('閉じ�?,
                      style: TextStyle(color: AppColors.text2)),
                ),
              ),
            ] else ...[

              Text('フィードバッ�?,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              const Text('ご意見・不具合をお知らせください',
                  style: TextStyle(fontSize: 14, color: AppColors.text2)),
              const SizedBox(height: 24),

              const SectionLabel('評価'),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final star = i + 1;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _rating = star);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        star <= _rating ? '�? : '�?,
                        style: TextStyle(
                          fontSize: 32,
                          color: star <= _rating
                              ? AppColors.peach : AppColors.text3,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              if (_rating > 0)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(_starLabels[_rating],
                        style: const TextStyle(
                          fontSize: 13, color: AppColors.text2)),
                  ),
                ),
              const SizedBox(height: 20),

              const SectionLabel('カテゴリ'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _categories.map((cat) {
                  final selected = _category == cat;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _category = cat);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.tealDim : Colors.transparent,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: selected ? AppColors.teal : AppColors.border2,
                        ),
                      ),
                      child: Text(cat,
                          style: TextStyle(
                            fontSize: 13,
                            color: selected ? AppColors.teal : AppColors.text2,
                            fontWeight: selected
                                ? FontWeight.w600 : FontWeight.normal,
                          )),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              const SectionLabel('詳細（任意）'),
              const SizedBox(height: 8),
              TextField(
                controller: _textCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'ご意見や不具合の内容をご記入ください',
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('送信する',
                          style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('キャンセ�?,
                      style: TextStyle(color: AppColors.text3)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
