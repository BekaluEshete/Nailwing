import 'dart:ui';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nilewing/features/chat/viewModel/call_view_model.dart';
import 'package:nilewing/core/theme/app_colors.dart';

class CallScreen extends ConsumerStatefulWidget {
  final String channelName;
  final String contactName;
  final bool isVideoCall;

  const CallScreen({
    Key? key,
    required this.channelName,
    required this.contactName,
    required this.isVideoCall,
  }) : super(key: key);

  @override
  ConsumerState<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends ConsumerState<CallScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  bool _isSpeakerOn = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(callViewModelProvider.notifier).initAgoraAndJoinChannel(
            channelName: widget.channelName,
            isVideoCall: widget.isVideoCall,
          );
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(callViewModelProvider);
    final viewModel = ref.read(callViewModelProvider.notifier);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF3F8CFF), // Light blue
              Color(0xFF6B52FF), // Purple
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Background Video Layer
              if (widget.isVideoCall && state.isJoined && viewModel.engine != null)
                Positioned.fill(
                  child: state.remoteUid != null
                      ? AgoraVideoView(
                          controller: VideoViewController.remote(
                            rtcEngine: viewModel.engine!,
                            canvas: VideoCanvas(uid: state.remoteUid),
                            connection: RtcConnection(channelId: widget.channelName),
                          ),
                        )
                      : AgoraVideoView(
                          controller: VideoViewController(
                            rtcEngine: viewModel.engine!,
                            canvas: const VideoCanvas(uid: 0),
                          ),
                        ),
                ),

              // Gradient Overlay (Subtle, only if video is on)
              if (widget.isVideoCall && state.isJoined && !state.isVideoMuted)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withOpacity(0.5),
                        ],
                      ),
                    ),
                  ),
                ),

              // UI Overlay
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.open_in_full, color: Colors.white, size: 28),
                          onPressed: () async {
                            await viewModel.leaveChannel();
                            if (mounted) Navigator.pop(context);
                          },
                        ),
                        // Right side icons like network status could go here
                        const Icon(Icons.info_outline, color: Colors.white, size: 28),
                      ],
                    ),
                  ),

                  // Center Content (Avatar & Name)
                  if (!widget.isVideoCall || state.remoteUid == null)
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (!widget.isVideoCall) ...[
                            AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: state.isJoined ? 1.0 : _pulseAnimation.value,
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withOpacity(0.1),
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withOpacity(0.2),
                                      ),
                                      child: const CircleAvatar(
                                        radius: 70,
                                        backgroundImage: NetworkImage(
                                          'https://i.pravatar.cc/300',
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 30),
                          ],
                          Text(
                            widget.contactName,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: widget.isVideoCall ? 28 : 32,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              state.remoteUid != null 
                                ? 'Connected' 
                                : (state.isJoined ? 'Calling...' : 'Requesting...'),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    const Spacer(),

                  // Bottom Controls
                  Padding(
                    padding: const EdgeInsets.only(bottom: 50, left: 30, right: 30),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildControlButton(
                          icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                          label: 'Speaker',
                          isOff: !_isSpeakerOn,
                          onPressed: () {
                            setState(() {
                              _isSpeakerOn = !_isSpeakerOn;
                              viewModel.engine?.setEnableSpeakerphone(_isSpeakerOn);
                            });
                          },
                        ),
                        if (widget.isVideoCall) ...[
                          _buildControlButton(
                            icon: Icons.flip_camera_ios,
                            label: 'Flip',
                            onPressed: viewModel.switchCamera,
                          ),
                          _buildControlButton(
                            icon: state.isVideoMuted ? Icons.videocam_off : Icons.videocam,
                            label: 'Video',
                            isOff: state.isVideoMuted,
                            onPressed: viewModel.toggleVideo,
                          ),
                        ],
                        _buildControlButton(
                          icon: state.isAudioMuted ? Icons.mic_off : Icons.mic,
                          label: 'Mute',
                          isOff: state.isAudioMuted,
                          onPressed: viewModel.toggleAudio,
                        ),
                        _buildControlButton(
                          icon: Icons.call_end,
                          label: 'End',
                          color: Colors.redAccent,
                          onPressed: () {
                            viewModel.leaveChannel();
                            if (mounted) Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Floating Local Video (Only when remote user is joined)
              if (widget.isVideoCall && state.isJoined && viewModel.engine != null && state.remoteUid != null)
                Positioned(
                  top: 80,
                  right: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: SizedBox(
                        width: 110,
                        height: 160,
                        child: AgoraVideoView(
                          controller: VideoViewController(
                            rtcEngine: viewModel.engine!,
                            canvas: const VideoCanvas(uid: 0),
                          ),
                        ),
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

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? color,
    bool isOff = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onPressed,
          child: Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color ?? (isOff ? Colors.white.withOpacity(0.3) : Colors.white.withOpacity(0.15)),
            ),
            child: Center(
              child: Icon(
                icon,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
      ],
    );
  }
}

