import 'package:flutter/material.dart';

class LoadingSubmitButton extends StatefulWidget {
  final bool enabled;
  final bool isLoading;
  final String label;
  final String loadingLabel;
  final VoidCallback onTap;

  const LoadingSubmitButton({
    super.key,
    required this.enabled,
    required this.isLoading,
    required this.label,
    required this.loadingLabel,
    required this.onTap,
  });

  @override
  State<LoadingSubmitButton> createState() => _LoadingSubmitButtonState();
}

class _LoadingSubmitButtonState extends State<LoadingSubmitButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final canInteract = widget.enabled && !widget.isLoading;

    return AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 100),
      child: GestureDetector(
        onTapDown: canInteract ? (_) => setState(() => _pressed = true) : null,
        onTapUp: canInteract ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: () => setState(() => _pressed = false),
        child: ElevatedButton(
          onPressed: canInteract ? widget.onTap : null,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: SizedBox(
            height: 20,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: widget.isLoading
                  ? Row(
                      key: const ValueKey('loading'),
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(widget.loadingLabel),
                      ],
                    )
                  : Text(key: const ValueKey('label'), widget.label),
            ),
          ),
        ),
      ),
    );
  }
}
