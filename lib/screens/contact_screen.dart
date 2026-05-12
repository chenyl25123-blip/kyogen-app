import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/models.dart';
import '../services/contact_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _contactService = ContactService();
  final _authService    = AuthService();

  Contact? _contact;
  bool _loading        = true;
  bool _googleLinked   = false;
  bool _googleSkipped  = false;
  bool _linkingGoogle  = false;
  bool _sendingTest    = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _checkGoogleLink();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final contact = await _contactService.getContact();
    setState(() {
      _contact = contact;
      _loading = false;
    });
  }

  void _checkGoogleLink() {
    final user = _authService.currentUser;
    if (user != null) {
      setState(() {
        _googleLinked = user.providerData
            .any((p) => p.providerId == 'google.com');
      });
    }
  }

  Future<void> _onGoogleLogin() async {
    setState(() => _linkingGoogle = true);
    HapticFeedback.mediumImpact();
    try {
      final result = await _authService.linkGoogleAccount();
      if (result != null) {
        setState(() => _googleLinked = true);
        _showSnack('Googleアカウントと連携しました �?);
      }
    } catch (e) {
      _showSnack('連携に失敗しました。もう一度お試しください');
    } finally {
      setState(() => _linkingGoogle = false);
    }
  }

  Future<void> _openEditSheet({bool isNew = false}) async {
    final result = await showModalBottomSheet<Contact>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ContactEditSheet(initial: _contact),
    );
    if (result != null) {
      await _contactService.saveContact(result);
      await _loadData();
      HapticFeedback.mediumImpact();
      _showSnack('保存しました。確認メールを送信しました 📨');
    }
  }

  Future<void> _sendTestEmail() async {
    setState(() => _sendingTest = true);
    HapticFeedback.mediumImpact();
    try {
      await FirebaseFunctions.instanceFor(region: 'asia-northeast1')
          .httpsCallable('sendTestEmail')
          .call();
      _showSnack('テストメールを送信しました 📨');
    } catch (e) {
      _showSnack('送信に失敗しました。もう一度お試しください');
    } finally {
      if (mounted) setState(() => _sendingTest = false);
    }
  }

  Future<void> _deleteContact() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bg2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('連絡先を削除',
            style: TextStyle(color: AppColors.text)),
        content: const Text('削除すると緊急時にメールを送れなくなります�?,
            style: TextStyle(color: AppColors.text2)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセ�?,
                style: TextStyle(color: AppColors.text3)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('削除する',
                style: TextStyle(
                  color: AppColors.plum, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _contactService.deleteContact();
      await _loadData();
      HapticFeedback.mediumImpact();
      _showSnack('連絡先を削除しました');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.teal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
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
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('緊急連絡�?,
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 4),
                          const Text('登録できる相手は1人のみで�?,
                              style: TextStyle(
                                fontSize: 14, color: AppColors.text2)),
                        ],
                      ),
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverList(delegate: SliverChildListDelegate([

                      // ── Google ログイン案内 ────────────
                      if (!_googleLinked && !_googleSkipped) ...[
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Googleアカウントで同期',
                                  style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w700,
                                    color: AppColors.text,
                                  )),
                              const SizedBox(height: 4),
                              const Text(
                                '機種変更や再インストール後も\n連絡先設定を引き継ぐことができます�?,
                                style: TextStyle(
                                  fontSize: 13, color: AppColors.text2,
                                  height: 1.5),
                              ),
                              const SizedBox(height: 16),
                              GoogleSignInButton(
                                onPressed: _onGoogleLogin,
                                isLoading: _linkingGoogle,
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () =>
                                    setState(() => _googleSkipped = true),
                                child: const Center(
                                  child: Text('スキップして続け�?,
                                      style: TextStyle(
                                        fontSize: 12, color: AppColors.text3)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // ── Google 連携済みバッ�?──────────
                      if (_googleLinked) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.tealDim,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.teal.withOpacity(0.3)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.check_circle_outline,
                                  color: AppColors.teal, size: 16),
                              SizedBox(width: 8),
                              Text('Googleアカウントと連携済み',
                                  style: TextStyle(
                                    fontSize: 12, color: AppColors.teal,
                                    fontWeight: FontWeight.w600,
                                  )),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // ── 連絡�?未設�?────────────────
                      if (_contact == null || !_contact!.isSet) ...[
                        AppCard(
                          child: Column(
                            children: [
                              Container(
                                width: 56, height: 56,
                                decoration: BoxDecoration(
                                  color: AppColors.peachDim,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.peach.withOpacity(0.4),
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(Icons.person_add_outlined,
                                    color: AppColors.peach, size: 26),
                              ),
                              const SizedBox(height: 14),
                              const Text('連絡�?未設�?,
                                  style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w700,
                                    color: AppColors.text,
                                  )),
                              const SizedBox(height: 6),
                              const Text(
                                '今のままでも使えますが、\n緊急時に通知できる相手がいません�?,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13, color: AppColors.text2,
                                  height: 1.5),
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () =>
                                      _openEditSheet(isNew: true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.teal,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14)),
                                    elevation: 0,
                                  ),
                                  child: const Text('今すぐ設定す�?,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // ── 連絡�?設定済み ───────────────
                      if (_contact != null && _contact!.isSet) ...[
                        AppCard(
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  _ContactAvatar(name: _contact!.name),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(_contact!.name,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.text,
                                            )),
                                        if (_contact!.relationship != null)
                                          Text(_contact!.relationship!,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.text2)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Divider(height: 1, color: AppColors.border),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Text('メー�?,
                                      style: TextStyle(
                                        fontSize: 11, color: AppColors.text3,
                                        letterSpacing: 0.1,
                                      )),
                                  const Spacer(),
                                  Text(_contact!.email,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.text2)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        if (_contact!.confirmedAt != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.tealDim,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppColors.teal.withOpacity(0.25)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.mark_email_read_outlined,
                                    color: AppColors.teal, size: 16),
                                SizedBox(width: 8),
                                Text('確認メールを送信しました',
                                    style: TextStyle(
                                      fontSize: 12, color: AppColors.teal,
                                      fontWeight: FontWeight.w600,
                                    )),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],

                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('送信メッセージのプレビュ�?,
                                  style: TextStyle(
                                    fontSize: 10, color: AppColors.text3,
                                    letterSpacing: 0.1,
                                  )),
                              const SizedBox(height: 8),
                              Text(
                                '�?{_contact!.name}さんの様子をご確認ください�?
                                '3日以上ご連絡がありません。�?,
                                style: const TextStyle(
                                  fontSize: 13, color: AppColors.text2,
                                  height: 1.5),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        AppCard(
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: [
                              SettingsRow(
                                title: '情報を変更す�?,
                                trailing: const Icon(Icons.chevron_right,
                                    size: 18, color: AppColors.text3),
                                onTap: _openEditSheet,
                                showDivider: false,
                              ),
                              SettingsRow(
                                title: 'テストメールを送信',
                                trailing: _sendingTest
                                    ? const SizedBox(
                                        width: 16, height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.teal,
                                        ),
                                      )
                                    : const Icon(Icons.chevron_right,
                                        size: 18, color: AppColors.text3),
                                onTap: _sendingTest ? null : _sendTestEmail,
                              ),
                              SettingsRow(
                                title: '連絡先を削除する',
                                trailing: const Icon(Icons.chevron_right,
                                    size: 18, color: AppColors.plum),
                                onTap: _deleteContact,
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 40),
                    ])),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ContactAvatar extends StatelessWidget {
  final String name;
  const _ContactAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56, height: 56,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [AppColors.teal, Color(0xFF5A8A96)],
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name.characters.first : '?',
          style: const TextStyle(
            fontSize: 22, fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _ContactEditSheet extends StatefulWidget {
  final Contact? initial;
  const _ContactEditSheet({this.initial});

  @override
  State<_ContactEditSheet> createState() => _ContactEditSheetState();
}

class _ContactEditSheetState extends State<_ContactEditSheet> {
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _relCtrl   = TextEditingController();
  final _formKey   = GlobalKey<FormState>();
  bool _saving     = false;

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      _nameCtrl.text  = widget.initial!.name;
      _emailCtrl.text = widget.initial!.email;
      _relCtrl.text   = widget.initial!.relationship ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _relCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final contact = Contact(
      name:         _nameCtrl.text.trim(),
      email:        _emailCtrl.text.trim(),
      relationship: _relCtrl.text.trim().isEmpty ? null : _relCtrl.text.trim(),
      updatedAt:    DateTime.now(),
    );

    Navigator.pop(context, contact);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(bottom: bottom),
      decoration: const BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
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

            Text('連絡先を編集',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            const Text('保存すると相手に確認メールが自動送信されます',
                style: TextStyle(fontSize: 12, color: AppColors.text2)),
            const SizedBox(height: 20),

            const SectionLabel('お名�?),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(hintText: '�? 田中 花子'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'お名前を入力してください' : null,
            ),
            const SizedBox(height: 14),

            const SectionLabel('メールアドレ�?),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(hintText: 'hanako@example.com'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'メールを入力してください';
                if (!v.contains('@')) return '正しいメールアドレスを入力してくださ�?;
                return null;
              },
            ),
            const SizedBox(height: 14),

            const SectionLabel('続柄（任意）'),
            TextFormField(
              controller: _relCtrl,
              decoration: const InputDecoration(hintText: '�? �?/ 友人 / �?),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('保存して確認メールを送信',
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
                    style: TextStyle(color: AppColors.text3, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
