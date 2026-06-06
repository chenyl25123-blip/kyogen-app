import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      await NotificationService().initialize();
    } catch (e, st) {
      runApp(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '起動エラー:\n$e\n\n$st',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ),
        ),
      );
      return;
    }
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const ProviderScope(child: KyogenApp()));
}

class KyogenApp extends StatelessWidget {
  const KyogenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'まもりんく',
      theme: AppTheme.theme,
      debugShowCheckedModeBanner: false,
      home: const AppRouter(),
    );
  }
}

class AppRouter extends StatefulWidget {
  const AppRouter({super.key});

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  final AuthService? _auth = kDemoMode ? null : AuthService();
  final _notifications = NotificationService();
  bool _isInitializing = true;

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
    // authStateChanges の最初の emit を待ってから判定
    // currentUser はまだ null の場合があるため直接参照しない
    final user = await FirebaseAuth.instance.authStateChanges().first;
    if (user != null) {
      _notifications.saveToken();
    }
    if (mounted) setState(() => _isInitializing = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (kDemoMode) return const MainScreen();

    return StreamBuilder<User?>(
      stream: _auth!.userStream,
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
