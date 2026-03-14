import 'package:flutter_riverpod/flutter_riverpod.dart';

class CallState {
  final bool isJoined;
  final bool isAudioMuted;
  final bool isVideoMuted;
  final int? remoteUid;
  final bool isVideoCall;
  final String? channelName;

  const CallState({
    this.isJoined = false,
    this.isAudioMuted = false,
    this.isVideoMuted = false,
    this.remoteUid,
    this.isVideoCall = true,
    this.channelName,
  });

  CallState copyWith({
    bool? isJoined,
    bool? isAudioMuted,
    bool? isVideoMuted,
    int? remoteUid,
    bool? isVideoCall,
    String? channelName,
  }) {
    return CallState(
      isJoined: isJoined ?? this.isJoined,
      isAudioMuted: isAudioMuted ?? this.isAudioMuted,
      isVideoMuted: isVideoMuted ?? this.isVideoMuted,
      remoteUid: remoteUid ?? this.remoteUid, // Handle null setting properly in viewmodel
      isVideoCall: isVideoCall ?? this.isVideoCall,
      channelName: channelName ?? this.channelName,
    );
  }
}
