import 'package:blog_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

enum ToastType { info, success, error }

class DevlogToast {
  static OverlayEntry? _entry;

  static void show(
    BuildContext context,
    String message, {
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);
    final colors = Theme.of(context).extension<DevlogColors>()!;

    _entry?.remove();
    _entry = null;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => ToastCard(
        message: message,
        type: type,
        colors: colors,
        duration: duration,
        onDismissed: () {
          entry.remove();
          if (_entry == entry) _entry = null;
        },
      ),
    );

    _entry = entry;
    overlay.insert(entry);
  }
}

class ToastCard extends StatefulWidget {
  final String message;
  final ToastType type;
  final DevlogColors colors;
  final Duration duration;
  final VoidCallback onDismissed;
  const ToastCard({
    super.key,
    required this.message,
    required this.type,
    required this.colors,
    required this.duration,
    required this.onDismissed,
  });

  @override
  State<ToastCard> createState() => _ToastCardState();
}

class _ToastCardState extends State<ToastCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    reverseDuration: const Duration(milliseconds: 220),
  );

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
    reverseCurve: Curves.easeIn,
  );

  late final Animation<double> _scale = Tween<double>(begin: 0.9, end: 1.0)
      .animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeIn,
        ),
      );

  late final Animation<Offset> _slide =
      Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeIn,
        ),
      );

  @override
  void initState() {
    super.initState();
    _controller.forward();
    Future.delayed(widget.duration, () async {
      if (!mounted) return;
      await _controller.reverse();
      widget.onDismissed();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    final (Color bg, IconData icon) = switch (widget.type) {
      ToastType.success => (const Color(0xFF1E8E5A), Icons.check_rounded),
      ToastType.error => (c.danger, Icons.close_rounded),
      ToastType.info => (c.text, Icons.info_rounded),
    };
    final fg = widget.type == ToastType.info ? c.bg : Colors.white;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 40,
      child: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: ScaleTransition(
                scale: _scale,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 340),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.fromLTRB(10, 10, 16, 10),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: fg.withValues(alpha: 0.18),
                          ),
                          child: Icon(icon, size: 15, color: fg),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            widget.message,
                            style: TextStyle(
                              color: fg,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
