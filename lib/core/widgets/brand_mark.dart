import 'package:blog_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DevlogBrand extends StatefulWidget {
  final double size;
  const DevlogBrand({super.key, this.size = 16});

  @override
  State<DevlogBrand> createState() => _DevlogBrandState();
}

class _DevlogBrandState extends State<DevlogBrand>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  late final Animation<double> _blink = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOut,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<DevlogColors>()!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _BrandGlyph(size: widget.size * 1.2, pulse: _blink),
        SizedBox(width: widget.size * 0.3),
        Text(
          'byteJournal',
          style: TextStyle(
            fontSize: widget.size,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            color: c.text,
          ),
        ),
        AnimatedBuilder(
          animation: _blink,
          builder: (context, child) =>
              Opacity(opacity: _blink.value, child: child),
          child: Container(
            margin: EdgeInsets.only(left: widget.size * 0.14),
            width: widget.size * 0.09,
            height: widget.size * 0.7,
            decoration: BoxDecoration(
              color: c.accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ],
    );
  }
}

class _BrandGlyph extends StatelessWidget {
  final double size;
  final Animation<double> pulse;

  const _BrandGlyph({required this.size, required this.pulse});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, child) =>
          Transform.scale(scale: 0.95 + (pulse.value * 0.05), child: child),
      child: SvgPicture.asset(
        'assets/icons/app_logo.svg',
        width: size,
        height: size,
      ),
    );
  }
}
