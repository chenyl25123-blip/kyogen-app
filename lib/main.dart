import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kyogen/demo_mode.dart';
import 'package:kyogen/firebase_options.dart';
import 'package:kyogen/theme/app_theme.dart';
import 'package:kyogen/screens/onboarding_screen.dart';
import 'package:kyogen/screens/main_screen.dart';
import 'package:kyogen/services/auth_service.dart';
import 'package:kyogen/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kDemoMode) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await NotificationService().initialize();
  }

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  runApp(const ProviderScope(child: KyogenApp()));
}

class KyogenApp extends StatelessWidget {
  const KyogenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title:            '今日も元気',
      theme:            AppTheme.theme,
      debugShowCheckedModeBanner: false,
      home:             const AppRouter(),
    );
  }
}

class AppRouter extends StatefulWidget {
  const AppRouter({super.key});

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  final _auth            = AuthService();
  final _notifications   = NotificationService();
  bool _isInitializing   = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    if (kDemoMode) {
      if (mounted) setState(() => _isInitializing = false);
      return;
    }
    // 既存ユーザーがいる場合のみトークンを更新（新規ユーザーは OnboardingScreen で処理）
    if (FirebaseAuth.instance.currentUser != null) {
      _notifications.saveToken();
    }
    if (mounted) setState(() => _isInitializing = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (kDemoMode) return const MainScreen();

    return StreamBuilder<User?>(
      stream: _auth.userStream,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snap.data;
        if (user == null) return const OnboardingScreen();
        return const MainScreen();
      },
    );
  }
}
