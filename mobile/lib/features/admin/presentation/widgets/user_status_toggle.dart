import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A premium styled toggle button for enabling/disabling users
/// Features optimistic updates and animated feedback
class UserStatusToggle extends StatefulWidget {
  final bool isEnabled;
  final Future<bool> Function(bool newValue) onToggle;
  final String? enabledLabel;
  final String? disabledLabel;

  const UserStatusToggle({
    super.key,
    required this.isEnabled,
    required this.onToggle,
    this.enabledLabel,
    this.disabledLabel,
  });

  @override
  State<UserStatusToggle> createState() => _UserStatusToggleState();
}

class _UserStatusToggleState extends State<UserStatusToggle> {
  late bool _optimisticValue;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _optimisticValue = widget.isEnabled;
  }

  @override
  void didUpdateWidget(UserStatusToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync with parent if not loading (external state change)
    if (!_isLoading && widget.isEnabled != _optimisticValue) {
      _optimisticValue = widget.isEnabled;
    }
  }

  Future<void> _handleTap() async {
    if (_isLoading) return;

    final newValue = !_optimisticValue;

    // Optimistic update - immediately show the new state
    setState(() {
      _optimisticValue = newValue;
      _isLoading = true;
    });

    // Perform the actual API call
    final success = await widget.onToggle(newValue);

    if (mounted) {
      if (!success) {
        // Revert on failure
        setState(() {
          _optimisticValue = !newValue;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: _handleTap,
      child:
          AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: _optimisticValue
                      ? LinearGradient(
                          colors: [
                            Colors.green.shade400,
                            Colors.green.shade600,
                          ],
                        )
                      : LinearGradient(
                          colors: isDark
                              ? [Colors.grey.shade700, Colors.grey.shade800]
                              : [Colors.grey.shade300, Colors.grey.shade400],
                        ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _optimisticValue
                          ? Colors.green.withOpacity(0.3)
                          : Colors.grey.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isLoading)
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _optimisticValue
                                ? Colors.white
                                : (isDark ? Colors.white70 : Colors.black54),
                          ),
                        ),
                      )
                    else
                      Icon(
                        _optimisticValue ? Icons.check_circle : Icons.cancel,
                        size: 14,
                        color: _optimisticValue
                            ? Colors.white
                            : (isDark ? Colors.white70 : Colors.black54),
                      ),
                    const SizedBox(width: 6),
                    Text(
                      _optimisticValue
                          ? (widget.enabledLabel ?? 'Enabled')
                          : (widget.disabledLabel ?? 'Disabled'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _optimisticValue
                            ? Colors.white
                            : (isDark ? Colors.white70 : Colors.black54),
                      ),
                    ),
                  ],
                ),
              )
              .animate(target: _isLoading ? 1 : 0)
              .shimmer(duration: 1000.ms, color: Colors.white.withOpacity(0.3)),
    );
  }
}

/// A more compact chip-style toggle for tight spaces
class UserStatusChip extends StatefulWidget {
  final bool isEnabled;
  final Future<bool> Function(bool newValue) onToggle;

  const UserStatusChip({
    super.key,
    required this.isEnabled,
    required this.onToggle,
  });

  @override
  State<UserStatusChip> createState() => _UserStatusChipState();
}

class _UserStatusChipState extends State<UserStatusChip> {
  late bool _optimisticValue;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _optimisticValue = widget.isEnabled;
  }

  @override
  void didUpdateWidget(UserStatusChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isLoading && widget.isEnabled != _optimisticValue) {
      _optimisticValue = widget.isEnabled;
    }
  }

  Future<void> _handleTap() async {
    if (_isLoading) return;

    final newValue = !_optimisticValue;

    // Optimistic update
    setState(() {
      _optimisticValue = newValue;
      _isLoading = true;
    });

    final success = await widget.onToggle(newValue);

    if (mounted) {
      if (!success) {
        // Revert on failure
        setState(() {
          _optimisticValue = !newValue;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _handleTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _optimisticValue
                ? Colors.green.withOpacity(isDark ? 0.3 : 0.15)
                : Colors.grey.withOpacity(isDark ? 0.3 : 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _optimisticValue
                  ? Colors.green.withOpacity(0.5)
                  : Colors.grey.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isLoading)
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _optimisticValue ? Colors.green : Colors.grey,
                    ),
                  ),
                )
              else
                Icon(
                  _optimisticValue ? Icons.toggle_on : Icons.toggle_off,
                  size: 16,
                  color: _optimisticValue ? Colors.green : Colors.grey,
                ),
              const SizedBox(width: 4),
              Text(
                _optimisticValue ? 'ON' : 'OFF',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _optimisticValue
                      ? Colors.green
                      : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
