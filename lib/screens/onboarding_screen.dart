import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'main_screen.dart';

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
      vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() { _fadeCtrl.dispose(); super.dispose(); }

  Future<void> _start() async {
    setState(() => _starting = true);
    HapticFeedback.mediumImpact();

    // 匿名ログイン（まだしていなければ�?    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }

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
              children: [
                const SizedBox(height: 48),

                // アイコン
                Container(
                  width: 96, height: 96,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.teal, Color(0xFF5A8A96)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.teal.withOpacity(0.3),
                        blurRadius: 24, offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    size: 48, color: Colors.white,
                  ),
                ),
                const SizedBox(height: 28),

                // タイトル
                const Text('今日も元�?,
                  style: TextStyle(
                    fontSize: 32, fontWeight: FontWeight.w700,
                    color: AppColors.text,
                    fontFamily: 'ZenMaruGothic',
                  )),
                const SizedBox(height: 8),
                const Text('Daily Check-in',
                  style: TextStyle(
                    fontSize: 12, color: AppColors.text3,
                    letterSpacing: 0.25,
                  )),
                const SizedBox(height: 48),

                // ステップ説明
                _StepCard(
                  number: '1',
                  title: '毎日1回、ボタンをタップ',
                  desc: '時間は自由。朝でも夜でも�?�?回だけ�?,
                ),
                const SizedBox(height: 12),
                _StepCard(
                  number: '2',
                  title: '2日間未確認でプッシュ通知',
                  desc: 'まず自分へ警告が届きます�?,
                ),
                const SizedBox(height: 12),
                _StepCard(
                  number: '3',
                  title: '3日目に緊急連絡先へメー�?,
                  desc: '「○○さんの様子をご確認ください」が届きます�?,
                ),

                const Spacer(),

                // はじめるボタ�?                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _starting ? null : _start,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                      elevation: 0,
                    ),
                    child: _starting
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Text('はじめる',
                          style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w700,
                            fontFamily: 'ZenMaruGothic',
                          )),
                  ),
                ),
                const SizedBox(height: 12),

                const Text('無料・登録不�?,
                  style: TextStyle(fontSize: 12, color: AppColors.text3)),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final String number;
  final String title;
  final String desc;

  const _StepCard({
    required this.number,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: AppColors.tealDim,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.teal.withOpacity(0.3)),
            ),
            child: Center(
              child: Text(number,
                style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700,
                  color: AppColors.teal,
                )),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                  style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  )),
                const SizedBox(height: 4),
                Text(desc,
                  style: const TextStyle(
                    fontSize: 13, color: AppColors.text2, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
