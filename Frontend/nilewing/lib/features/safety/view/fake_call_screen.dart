import 'package:flutter/material.dart';
import 'package:nilewing/core/theme/app_colors.dart';
import 'dart:async';
import '../service/safety_action_service.dart';

class FakeCallScreen extends StatefulWidget {
  const FakeCallScreen({Key? key}) : super(key: key);

  @override
  State<FakeCallScreen> createState() => _FakeCallScreenState();
}

class _FakeCallScreenState extends State<FakeCallScreen> {
  final SafetyActionService _actionService = SafetyActionService();
  String _callerName = 'Mom';
  int _delaySeconds = 0;
  bool _isWaiting = false;
  Timer? _timer;

  void _startFakeCallTimer() {
    if (_delaySeconds == 0) {
      _triggerCallOverlay();
      return;
    }

    setState(() {
      _isWaiting = true;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Fake call scheduled in $_delaySeconds seconds.')),
    );

    _timer = Timer(Duration(seconds: _delaySeconds), () {
      if (mounted) {
        setState(() => _isWaiting = false);
        _triggerCallOverlay();
      }
    });
  }

  void _triggerCallOverlay() {
    _actionService.playRingtone();
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return _IncomingCallOverlay(
          callerName: _callerName,
          onDecline: () {
            _actionService.stopRingtone();
            Navigator.pop(context); // Close overlay
          },
          onAccept: () {
            _actionService.stopRingtone();
            Navigator.pop(context); // Close overlay
            // Could open an active call screen if needed
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
        title: const Text(
          'Fake Call',
          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.phone_in_talk_rounded, size: 80, color: Colors.purple),
            const SizedBox(height: 24),
            const Text(
              'Set up a fake incoming call to help you exit an uncomfortable situation.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            
            // Caller Name Input
            TextField(
              decoration: InputDecoration(
                labelText: 'Caller Name',
                hintText: 'e.g., Mom, Friend, Partner',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (val) => _callerName = val.isNotEmpty ? val : 'Mom',
            ),
            const SizedBox(height: 24),

            // Delay Selection
            const Text('When should it ring?', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              children: [
                _buildDelayChip('Now', 0),
                _buildDelayChip('10 sec', 10),
                _buildDelayChip('1 min', 60),
                _buildDelayChip('3 min', 180),
              ],
            ),

            const Spacer(),

            if (_isWaiting)
              Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      _timer?.cancel();
                      setState(() => _isWaiting = false);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                    child: const Text('Cancel Timer', style: TextStyle(color: Colors.white)),
                  )
                ],
              )
            else
              ElevatedButton(
                onPressed: _startFakeCallTimer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade600,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text(
                  'Set Fake Call',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDelayChip(String label, int seconds) {
    final isSelected = _delaySeconds == seconds;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _delaySeconds = seconds);
      },
      selectedColor: Colors.purple.shade100,
      labelStyle: TextStyle(
        color: isSelected ? Colors.purple.shade700 : Colors.black87,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
      ),
    );
  }
}

// Full screen overlay mimicking a phone call
class _IncomingCallOverlay extends StatelessWidget {
  final String callerName;
  final VoidCallback onDecline;
  final VoidCallback onAccept;

  const _IncomingCallOverlay({
    Key? key,
    required this.callerName,
    required this.onDecline,
    required this.onAccept,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1C1C1E),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),
            const Text('Incoming call...', style: TextStyle(color: Colors.white54, fontSize: 18)),
            const SizedBox(height: 16),
            Text(
              callerName,
              style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w400),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCallButton(
                  icon: Icons.call_end,
                  color: Colors.red,
                  label: 'Decline',
                  onTap: onDecline,
                ),
                _buildCallButton(
                  icon: Icons.call,
                  color: Colors.green,
                  label: 'Accept',
                  onTap: onAccept,
                ),
              ],
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildCallButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 75,
            height: 75,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 36),
          ),
        ),
        const SizedBox(height: 12),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
      ],
    );
  }
}
