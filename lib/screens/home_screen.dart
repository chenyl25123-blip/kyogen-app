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
    } catch (_) {}
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
    final today = _todayKey();
    _history[today] = true;
    _updatePulseSpeed(CheckInStatus.safe);
    if (mounted) {
      setState(() {
        _status = CheckInStatus.safe;
        _checkingIn = false;
        _lastCheckInLabel = 'たった今';
      });
      _showSnack('今日も元気！確認しました');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.slate,
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
              ? const Center(child: CircularProgressIndicator(color: AppColors.slate))
              : Column(
                  children: [
                    _buildHeader(),
                    if (_status == CheckInStatus.paused) _buildPauseBanner(),
                    // 円ボタンを先頭に（画面の主役）
                    Expanded(child: _buildCheckInButton()),
                    // ステータステキストは円の下
                    _buildStatusArea(),
                    _buildCalendar(),
                    _buildLastCheckIn(),
                    const SizedBox(height: 8),
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
                  Text('まもりんく',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(width: 4),
                  Container(
                    width: 6, height: 6,
                    decoration: BoxDecoration(
                      color: _accentColor, shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const Text('Daily Check-in',
                  style: TextStyle(
                    fontSize: 9, color: AppColors.text3,
                    letterSpacing: 0.8, fontWeight: FontWeight.w500,
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

  // ステータステキスト（円の下に配置）
  Widget _buildStatusArea() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Column(
        children: [
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 400),
            style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.w700,
              color: _accentColor,
            ),
            child: Text(_status.label, textAlign: TextAlign.center),
          ),
          const SizedBox(height: 4),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 400),
            style: const TextStyle(fontSize: 12, color: AppColors.text2),
            child: Text(_status.subtitle, textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }

  // カレンダー（カードなし・フローティング）
  Widget _buildCalendar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: WeeklyCalendar(history: _history),
    );
  }

  // 大きな円ボタン（アイコンのみ・テキストは下に移動）
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
              // 外側グロー
              Container(
                width: 220, height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _accentColor.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              // パルスリング（未確認時）
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
                            alpha: 0.55 * (2.0 - _pulseAnim.value)),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              // メイン円（アイコンのみ）
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: 224, height: 224,
                decoration: BoxDecoration(
                  color: isSafe ? AppColors.tealDim : AppColors.bg2,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _accentColor.withValues(alpha: isSafe ? 0.9 : 0.45),
                    width: isSafe ? 1.5 : 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _accentColor.withValues(alpha: 0.12),
                      blurRadius: 24, spreadRadius: 4,
                    ),
                  ],
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: _checkingIn
                        ? SizedBox(
                            key: const ValueKey('loading'),
                            width: 44, height: 44,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: _accentColor,
                            ),
                          )
                        : Icon(
                            key: ValueKey(_status),
                            isSafe
                                ? Icons.shield
                                : _status == CheckInStatus.alert
                                    ? Icons.warning_amber_rounded
                                    : Icons.shield_outlined,
                            size: 64,
                            color: _accentColor,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 最終確認（ヘアライン区切り・カードなし）
  Widget _buildLastCheckIn() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('前回の確認',
                  style: TextStyle(
                    fontSize: 9, color: AppColors.text3,
                    letterSpacing: 0.8, fontWeight: FontWeight.w600,
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
              size: 16, color: AppColors.text3),
        ],
      ),
    );
  }
}
