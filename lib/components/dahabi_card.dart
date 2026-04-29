import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/dahabi_theme.dart';

class DahabiCard extends StatefulWidget {
  final Widget child;
  final String? title;
  final bool hasGlow;
  final VoidCallback? onTap;

  const DahabiCard({
    super.key,
    required this.child,
    this.title,
    this.hasGlow = false,
    this.onTap,
  });

  @override
  State<DahabiCard> createState() => _DahabiCardState();
}

class _DahabiCardState extends State<DahabiCard> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) => setState(() => _isFocused = hasFocus),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            boxShadow: (widget.hasGlow || _isFocused)
                ? [
                    BoxShadow(
                      color: DahabiTheme.primary.withOpacity(_isFocused ? 0.6 : 0.3),
                      blurRadius: _isFocused ? 16 : 8,
                      spreadRadius: _isFocused ? 2 : 0,
                    )
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isFocused 
                      ? DahabiTheme.surfaceContainerHigh.withOpacity(0.9)
                      : DahabiTheme.surfaceContainer.withOpacity(0.7),
                  border: Border.all(
                    color: _isFocused 
                        ? DahabiTheme.primary 
                        : DahabiTheme.primaryContainer.withOpacity(0.2),
                    width: _isFocused ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.title != null) ...[
                      Text(
                        widget.title!.toUpperCase(),
                        style: DahabiTheme.labelCaps.copyWith(
                          color: _isFocused ? DahabiTheme.secondary : DahabiTheme.primary,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Divider(
                        color: DahabiTheme.primary.withOpacity(0.1),
                        height: 1,
                      ),
                      const SizedBox(height: 16),
                    ],
                    widget.child,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

