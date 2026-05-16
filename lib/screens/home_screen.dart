import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kyogen/models.dart';
import 'package:kyogen/services/checkin_service.dart';
import 'package:kyogen/theme/app_theme.dart';
import 'package:kyogen/common_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {

  final _service = CheckInService();

  CheckInStatus _status = CheckInStatus.pending;
  Map<String, bool> _history = {};
  bool _loading    = false;
  bool _checkingIn = false;
  String? _lastCheckInLabel;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  static const _colors = {
    CheckInStatus.safe:    AppColors.teal,
    CheckInStatus.pending: AppColors.peach,
    CheckInStatus.warn:    AppColors.peach,
    CheckInStatus.alert:   AppColors.plum,
    CheckInStatus.paused:  AppColors.text3,
  };

  static const _bgColors = {
    CheckInStatus.safe:    Color(0x1A7BA8B5),
    CheckInStatus.pending: Color(0x14E8A57C),
    CheckInStatus.warn:    Color(0x1AE8A57C),
    CheckInStatus.alert:   Color(0x148E5973),
    CheckInStatus.paused:  Color(0x08000000),
  };

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.22).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _loadData();
  }

  Future<void> reload() => _loadData();

  Future<void> _loadData() async {
    try {
      final status  = await _service.getStatus()
          .timeout(const Duration(seconds: 3));
      final history = await _service.getHistory(7)
          .timeout(const Duration(seconds: 3));
      _updatePulseSpeed(status);
      if (!mounted) return;
      setState(() {
        _status           = status;
        _history          = history;
        _lastCheckInLabel = _buildLastCheckInLabel(history);
      });
    } catch (_) {
      // Firebase unavailable — keep default UI, don't block
    }
  }

  void _updatePulseSpeed(CheckInStatus status) {
    _pulseCtrl.stop();
    final ms = switch (status) {
      CheckInStatus.safe    => 3200,
      CheckInStatus.pending => 1800,
      CheckInStatus.warn    => 1200,
      CheckInStatus.alert   => 900,
      CheckInStatus.paused  => 3200,
      _ => 1800,
    };
    _pulseCtrl.duration = Duration(milliseconds: ms);
    _pulseCtrl.repeat(reverse: true);
  }

  String _todayKey() {
    final jst = DateTime.now().toUtc().add(const Duration(hours: 9));
    return '${jst.year}-${jst.month.toString().padLeft(2,'0')}-${jst.day.toString().padLeft(2,'0')}';
  }

  void _debugSimulateNextDay() {
    const order = [
      CheckInStatus.safe,
      CheckInStatus.pending,
      CheckInStatus.warn,
      CheckInStatus.alert,
    ];
    final next = order[(order.indexOf(_status) + 1) % order.length];
    _updatePulseSpeed(next);
    setState(() {
      _status = next;
      _lastCheckInLabel = next == CheckInStatus.safe ? 'たった今' : 'まだ確認していません';
    });
  }

  // history の範囲内のみ探索（範囲外は常に null になるため）
  String _buildLastCheckInLabel(Map<String, bool> history) {
    final jst = DateTime.now().toUtc().add(const Duration(hours: 9));
    for (int i = 0; i < history.length; i++) {
      final d   = jst.subtract(Duration(days: i));
      final key = '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
      if (history[key] == true) {
        if (i == 0) return 'たった今';
        if (i == 1) return '昨日';
        return '${i}日前';
      }
    }
    return 'まだ確認していません';
  }

  Future<void> _onCheckIn() async {
    if (_status == CheckInStatus.safe) {
      HapticFeedback.mediumImpact();
      _showSnack('本日は確認済みです ✓');
      return;
    }
    if (_status == CheckInStatus.paused) {
      HapticFeedback.mediumImpact();
      _showSnack('機能停止中です。設定から再開できます');
      return;
    }

    setState(() => _checkingIn = true);
    HapticFeedback.heavyImpact();
    try {
      await _service.checkIn().timeout(const Duration(seconds: 3));
    } catch (_) {}
    // 即座にUIを更新（Firebase成否に関わらず）
    final today = _todayKey();
    _history[today] = true;
    _updatePulseSpeed(CheckInStatus.safe);
    if (mounted) {
      setState(() {
        _status = CheckInStatus.safe;
        _checkingIn = false;
        _lastCheckInLabel = 'たった今';
      });
      _showSnack('今日も元気！確認しました 🌿');
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
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Color get _accentColor => _colors[_status] ?? AppColors.peach;
  Color get _bgColor     => _bgColors[_status] ?? Colors.transparent;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 900),
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topCenter,
          radius: 1.2,
          colors: [_bgColor, AppColors.bg],
          stops: const [0.0, 0.55],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
              : Column(
                  children: [
                    _buildHeader(),
                    if (_status == CheckInStatus.paused) _buildPauseBanner(),
                    _buildStatusArea(),
                    _buildCalendar(),
                    Expanded(child: _buildCheckInButton()),
                    _buildLastCheckIn(),
                    const SizedBox(height: 16),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('今日も元気',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(width: 4),
                  Container(
                    width: 7, height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.teal, shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const Text('Daily Check-in',
                  style: TextStyle(
                    fontSize: 10, color: AppColors.text3,
                    letterSpacing: 0.25,
                  )),
            ],
          ),
          const Spacer(),
          if (kDebugMode)
            GestureDetector(
              onTap: _debugSimulateNextDay,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.bg3,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border2),
                ),
                child: const Text('翌日 →', style: TextStyle(fontSize: 11, color: AppColors.text2)),
              ),
            ),
          const SizedBox(width: 8),
          Row(
            children: [
              BlinkingDot(color: _accentColor),
              const SizedBox(width: 6),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 400),
                style: const TextStyle(fontSize: 12, color: AppColors.text2),
                child: Text(
                  _status == CheckInStatus.paused ? '停止中' : '見守り中',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPauseBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.peachDim,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.peach.withValues(alpha: 0.35)),
        ),
        child: const Row(
          children: [
            Icon(Icons.pause_circle_outline, color: AppColors.peach, size: 18),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('機能停止中',
                      style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700,
                        color: AppColors.peach,
                      )),
                  Text('通知もメールも送信されません',
                      style: TextStyle(fontSize: 11, color: AppColors.text2)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusArea() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 400),
            style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.w700,
              color: _accentColor,
              fontFamily: 'ZenMaruGothic',
            ),
            child: Text(_status.label),
          ),
          const SizedBox(height: 4),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 400),
            style: const TextStyle(fontSize: 13, color: AppColors.text2),
            child: Text(_status.subtitle, textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: WeeklyCalendar(history: _history),
    );
  }

  Widget _buildCheckInButton() {
    final isSafe = _status == CheckInStatus.safe;

    return Center(
      child: GestureDetector(
        onTap: _onCheckIn,
        child: SizedBox(
          width: 220, height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 220, height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _accentColor.withValues(alpha: 0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              if (!isSafe) AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, __) => Transform.scale(
                  scale: _pulseAnim.value,
                  child: Container(
                    width: 224, height: 224,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _accentColor.withValues(
                            alpha: 0.6 * (2.0 - _pulseAnim.value)),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: 224, height: 224,
                decoration: BoxDecoration(
                  color: isSafe ? AppColors.tealDim : AppColors.bg2,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _accentColor.withValues(alpha: isSafe ? 1.0 : 0.5),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _accentColor.withValues(alpha: 0.15),
                      blurRadius: 24, spreadRadius: 4,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      transitionBuilder: (child, anim) =>
                          ScaleTransition(scale: anim, child: child),
                      child: _checkingIn
                          ? const SizedBox(
                              key: ValueKey('loading'),
                              width: 40, height: 40,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: AppColors.teal,
                              ),
                            )
                          : Icon(
                              key: ValueKey(_status),
                              isSafe
                                  ? Icons.shield
                                  : _status == CheckInStatus.alert
                                      ? Icons.warning_amber_rounded
                                      : Icons.shield_outlined,
                              size: 52,
                              color: _accentColor,
                            ),
                    ),
                    const SizedBox(height: 8),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 400),
                      style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: _accentColor,
                        fontFamily: 'ZenMaruGothic',
                      ),
                      child: Text(
                        isSafe ? '確認済み' : '今日も元気！',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLastCheckIn() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('前回の確認',
                    style: TextStyle(
                      fontSize: 10, color: AppColors.text3, letterSpacing: 0.1,
                    )),
                const SizedBox(height: 2),
                Text(
                  _lastCheckInLabel ?? 'まだ確認していません',
                  style: const TextStyle(fontSize: 13, color: AppColors.text2),
                ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.access_time_rounded,
                size: 18, color: AppColors.text3),
          ],
        ),
      ),
    );
  }
}
