import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ── 角丸カー�?─────────────────────────────────────────
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color ?? AppColors.bg2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: child,
      ),
    );
  }
}

// ── セクションラベル ───────────────────────────────────
class SectionLabel extends StatelessWidget {
  final String text;
  final EdgeInsetsGeometry? padding;

  const SectionLabel(this.text, {super.key, this.padding});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.text3,
          letterSpacing: 0.15,
        ),
      ),
    );
  }
}

// ── 設定行（トグル付き） ───────────────────────────────
class SettingsRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;

  const SettingsRow({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showDivider)
          const Divider(height: 1, color: AppColors.border),
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                        style: const TextStyle(fontSize: 14, color: AppColors.text)),
                      if (subtitle != null)
                        Text(subtitle!,
                          style: const TextStyle(fontSize: 11, color: AppColors.text3)),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── カスタムトグルスイッ�?────────────────────────────
class AppToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const AppToggle({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48, height: 28,
        decoration: BoxDecoration(
          color: value ? AppColors.teal : AppColors.bg3,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: value ? AppColors.teal : AppColors.border,
          ),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.all(3),
            width: 22, height: 22,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
          ),
        ),
      ),
    );
  }
}

// ── ステータスドット（点滅） ──────────────────────────
class BlinkingDot extends StatefulWidget {
  final Color color;
  final double size;
  const BlinkingDot({super.key, required this.color, this.size = 8});

  @override
  State<BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<BlinkingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 1.0, end: 0.2).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: widget.size, height: widget.size,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}

// ── Google サインインボタン ───────────────────────────
class GoogleSignInButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;

  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.bg2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8, offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isLoading
          ? const Center(
              child: SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.teal,
                ),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Google ロゴ (SVG相当をCustomPainterで描�?
                _GoogleLogo(),
                const SizedBox(width: 10),
                const Text(
                  'Googleでログイン（推奨�?,
                  style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 20, height: 20,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final center = rect.center;
    final r = size.width / 2;

    // 簡易Googleロゴ (4色の�?
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 3;

    // �?(上右)
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, -1.2, 1.6, false, paint);

    // �?(右下)
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, 0.4, 1.2, false, paint);

    // �?(下左)
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 1.6, 1.6, false, paint);

    // �?(左上)
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, 3.2, 1.2, false, paint);

    // 右側の横線（Gのバー）
    paint.strokeWidth = 3;
    paint.color = const Color(0xFF4285F4);
    canvas.drawLine(
      Offset(center.dx, center.dy),
      Offset(size.width, center.dy),
      paint,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── 7日間カレンダ�?───────────────────────────────────
class WeeklyCalendar extends StatelessWidget {
  final Map<String, bool> history; // {'2025-11-15': true, ...}

  const WeeklyCalendar({super.key, required this.history});

  String _dateKey(int offsetFromToday) {
    final jst = DateTime.now().toUtc().add(const Duration(hours: 9));
    final d = jst.subtract(Duration(days: offsetFromToday));
    return '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
  }

  @override
  Widget build(BuildContext context) {
    const dayLabels = ['�?, '�?, '�?, '�?, '�?, '�?, '�?];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final offsetFromToday = 6 - i; // 6日前 �?今日
        final key     = _dateKey(offsetFromToday);
        final isToday = offsetFromToday == 0;
        final checked = history[key] ?? false;

        final jst = DateTime.now().toUtc().add(const Duration(hours: 9));
        final d   = jst.subtract(Duration(days: offsetFromToday));
        final dayLabel = dayLabels[d.weekday % 7];

        return Column(
          children: [
            _DayDot(isToday: isToday, checked: checked, date: d.day),
            const SizedBox(height: 4),
            Text(dayLabel,
              style: const TextStyle(fontSize: 9, color: AppColors.text3)),
          ],
        );
      }),
    );
  }
}

class _DayDot extends StatelessWidget {
  final bool isToday;
  final bool checked;
  final int date;

  const _DayDot({required this.isToday, required this.checked, required this.date});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    BoxBorder? border;

    if (checked && isToday) {
      bg = AppColors.teal; fg = Colors.white;
      border = Border.all(color: Colors.white, width: 2);
    } else if (checked) {
      bg = AppColors.teal; fg = Colors.white;
    } else if (isToday) {
      bg = Colors.transparent; fg = AppColors.text3;
      border = Border.all(color: AppColors.border2, width: 2);
    } else {
      bg = AppColors.plumDim; fg = AppColors.plum;
      border = Border.all(color: AppColors.plum.withOpacity(0.25));
    }

    return Container(
      width: 30, height: 30,
      decoration: BoxDecoration(
        color: bg, shape: BoxShape.circle, border: border,
      ),
      child: Center(
        child: checked
          ? const Icon(Icons.check, size: 14, color: Colors.white)
          : Text(
              isToday ? date.toString() : '×',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
      ),
    );
  }
}
