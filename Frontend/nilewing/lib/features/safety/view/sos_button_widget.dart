import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:ui';
import 'package:nilewing/core/theme/app_colors.dart';
import 'package:nilewing/features/home/viewmodel/home_view_model.dart';
import '../service/safety_action_service.dart';
import '../service/safety_storage_service.dart';
import '../model/safety_model.dart';

class SOSButtonWidget extends ConsumerStatefulWidget {
  const SOSButtonWidget({Key? key}) : super(key: key);

  @override
  ConsumerState<SOSButtonWidget> createState() => _SOSButtonWidgetState();
}

class _SOSButtonWidgetState extends ConsumerState<SOSButtonWidget>
    with TickerProviderStateMixin {
  bool _isPressed = false;
  int _countdown = 3;
  Timer? _holdTimer;
  final SafetyActionService _actionService = SafetyActionService();
  final SafetyStorageService _storageService = SafetyStorageService();

  late AnimationController _pulseController;
  late AnimationController _rippleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rippleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _rippleAnimation = Tween<double>(begin: 0.85, end: 1.3).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _pulseController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  void _onPressStart(TapDownDetails details) {
    setState(() {
      _isPressed = true;
      _countdown = 3;
    });
    _holdTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
        _triggerSOS();
      }
    });
  }

  void _onPressEnd(TapUpDetails details) => _cancelSOS();
  void _onPressCancel() => _cancelSOS();

  void _cancelSOS() {
    _holdTimer?.cancel();
    if (mounted) setState(() { _isPressed = false; _countdown = 3; });
  }

  Future<void> _triggerSOS() async {
    if (!mounted) return;
    setState(() => _isPressed = false);

    final viewModel = ref.read(homeViewModelProvider);
    final flight = viewModel.userFlight;
    final user = viewModel.user;

    final String userName = user?.name ?? 'Traveler';
    final String airportCode = flight?.arrival.airport ?? 'Unknown';
    final String flightNumber = flight?.flightNumber ?? 'N/A';

    // Check if we have contacts
    final contacts = await _storageService.getTrustedContacts();
    if (contacts.isEmpty && mounted) {
      _showSnackBar('No trusted contacts found. Please add contacts first.', isError: true);
      return;
    }

    try {
      await _actionService.sendSOSToTrustedContacts(userName, airportCode, flightNumber);
      if (mounted) _showSnackBar('SOS Alert sent to ${contacts.length} trusted contact(s)!', isError: false);
    } catch (e) {
      if (mounted) _showSnackBar('Could not send SOS. Please try again.', isError: true);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.w600))),
          ],
        ),
        backgroundColor: isError ? const Color(0xFFDC2626) : const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.red.withOpacity(0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.08),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.sos_rounded, color: Colors.red, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Emergency SOS',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Hold 3s to alert trusted contacts',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 28),
              GestureDetector(
                onTapDown: _onPressStart,
                onTapUp: _onPressEnd,
                onTapCancel: _onPressCancel,
                child: AnimatedBuilder(
                  animation: Listenable.merge([_pulseAnimation, _rippleAnimation]),
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer ripple
                        if (!_isPressed)
                          Transform.scale(
                            scale: _rippleAnimation.value,
                            child: Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.red.withOpacity(0.08),
                              ),
                            ),
                          ),
                        // Inner ripple
                        if (!_isPressed)
                          Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              width: 130,
                              height: 130,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.red.withOpacity(0.12),
                              ),
                            ),
                          ),
                        // Button itself
                        Transform.scale(
                          scale: _isPressed ? 0.92 : _pulseAnimation.value,
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: _isPressed
                                    ? [const Color(0xFF991B1B), const Color(0xFFDC2626)]
                                    : [const Color(0xFFDC2626), const Color(0xFFEF4444)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(_isPressed ? 0.55 : 0.35),
                                  blurRadius: _isPressed ? 8 : 24,
                                  spreadRadius: _isPressed ? 0 : 2,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Center(
                              child: _isPressed
                                  ? Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '$_countdown',
                                          style: const TextStyle(
                                            fontSize: 44,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                            height: 1,
                                          ),
                                        ),
                                        const Text(
                                          'sec',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.white70,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    )
                                  : const Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.sos_rounded, size: 44, color: Colors.white),
                                        SizedBox(height: 2),
                                        Text(
                                          'HOLD',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white70,
                                            letterSpacing: 2,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              AnimatedOpacity(
                opacity: _isPressed ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Alert sent to all trusted contacts with your location',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w500,
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
}
