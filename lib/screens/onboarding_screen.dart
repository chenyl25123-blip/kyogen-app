import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kyogen/services/auth_service.dart';
import 'package:kyogen/services/notification_service.dart';
import 'package:kyogen/theme/app_theme.dart';
import 'package:kyogen/screens/main_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {

  final _auth = AuthService();
  bool _starting = false;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() { _fadeCtrl.dispose(); super.dispose(); }

  Future<void> _start() async {
    setState(() => _starting = true);
    HapticFeedback.mediumImpact();

    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }
    NotificationService().saveToken();

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const MainScreen(),
          transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // スキップ
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 4),
                    child: GestureDetector(
                      onTap: _starting ? null : _start,
                      child: const Text(
                        'スキップ',
                        style: TextStyle(fontSize: 13, color: AppColors.text3),
                      ),
                    ),
                  ),
                ),

                // アイコン（羁絆紐帯）
                Center(child: _buildAppIcon()),
                const SizedBox(height: 28),

                // タイトル
                const Center(
                  child: Text(
                    'まもりんく',
                    style: TextStyle(
                      fontSize: 30, fontWeight: FontWeight.w700,
                      color: AppColors.text, letterSpacing: 0.4,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Center(
                  child: Text(
                    'つながりで、見守る安心。',
                    style: TextStyle(
                      fontSize: 13, color: AppColors.text2,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                const Center(
                  child: Text(
                    'DAILY CHECK-IN',
                    style: TextStyle(
                      fontSize: 9, color: AppColors.text3,
                      letterSpacing: 1.8, fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // ステップ（カードなし・番号＋ヘアライン）
                _buildStep('01', '毎日1回、ボタンをタップ',
                    '時間は自由。朝でも夜でも、1日1回だけ。'),
                const SizedBox(height: 18),
                _buildStep('02', '2日間未確認でプッシュ通知',
                    'まず自分へ警告が届きます。'),
                const SizedBox(height: 18),
                _buildStep('03', '3日目に緊急連絡先へメール',
                    '「○○さんの様子をご確認ください」が届きます。'),

                const Spacer(),

                // ピル型CTAボタン
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _starting ? null : _start,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.slate,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.slate.withValues(alpha: 0.5),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: const StadiumBorder(),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                    ),
                    child: _starting
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Text(
                          'はじめる',
                          style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                  ),
                ),
                const SizedBox(height: 11),
                const Center(
                  child: Text(
                    '無料・登録不要',
                    style: TextStyle(fontSize: 11, color: AppColors.text3),
                  ),
                ),
                const SizedBox(height: 36),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 羁絆紐帯アイコン
  Widget _buildAppIcon() {
    return Container(
      width: 100, height: 100,
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20, offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: SizedBox(
          width: 60, height: 38,
          child: Stack(
            children: [
              Positioned(
                left: 0, top: 1,
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFB8C5D4), width: 5,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 0, top: 1,
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.amber, width: 5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.amber.withValues(alpha: 0.38),
                        blurRadius: 12, spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 番号＋ヘアライン＋テキスト（カードなし）
  Widget _buildStep(String num, String title, String desc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              num,
              style: const TextStyle(
                fontSize: 11, color: AppColors.text3,
                fontStyle: FontStyle.italic,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: Container(height: 1, color: AppColors.border)),
          ],
        ),
        const SizedBox(height: 9),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w700,
            color: AppColors.text, letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          desc,
          style: const TextStyle(
            fontSize: 12, color: AppColors.text2, height: 1.6,
          ),
        ),
      ],
    );
  }
}
