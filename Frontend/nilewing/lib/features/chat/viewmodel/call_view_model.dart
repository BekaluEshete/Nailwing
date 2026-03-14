import 'package:flutter/foundation.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:nilewing/features/chat/viewModel/call_state.dart';

final callViewModelProvider =
    StateNotifierProvider<CallViewModel, CallState>((ref) {
  return CallViewModel();
});

class CallViewModel extends StateNotifier<CallState> {
  RtcEngine? _engine;
  final String appId = "34bd620afe6f4ccd92f7d6715a0e3b21";

  CallViewModel() : super(const CallState());

  RtcEngine? get engine => _engine;

  Future<void> initAgoraAndJoinChannel({
    required String channelName,
    required bool isVideoCall,
  }) async {
    // Request permissions (skip on Web because browser handles this automatically)
    if (!kIsWeb) {
      await [Permission.microphone, Permission.camera].request();
    }

    // Create ATC engine instance
    _engine = createAgoraRtcEngine();
    await _engine!.initialize(RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    state = state.copyWith(
      isVideoCall: isVideoCall,
      channelName: channelName,
      isAudioMuted: false,
      isVideoMuted: !isVideoCall,
      isJoined: false,
      remoteUid: null,
    );

    // Register event handlers
    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          state = state.copyWith(isJoined: true);
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          state = CallState(
            isJoined: state.isJoined,
            isAudioMuted: state.isAudioMuted,
            isVideoMuted: state.isVideoMuted,
            remoteUid: remoteUid,
            isVideoCall: state.isVideoCall,
            channelName: state.channelName,
          );
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          state = CallState(
            isJoined: state.isJoined,
            isAudioMuted: state.isAudioMuted,
            isVideoMuted: state.isVideoMuted,
            remoteUid: null,
            isVideoCall: state.isVideoCall,
            channelName: state.channelName,
          );
        },
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          state = state.copyWith(isJoined: false, remoteUid: null);
        },
      ),
    );

    if (isVideoCall) {
      await _engine!.enableVideo();
      await _engine!.startPreview();
    } else {
      await _engine!.enableAudio();
      await _engine!.disableVideo();
    }

    // Join channel
    await _engine!.joinChannel(
      token: "", // Using appId is enough for testing mode
      channelId: channelName,
      uid: 0,
      options: const ChannelMediaOptions(
        autoSubscribeAudio: true,
        autoSubscribeVideo: true,
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );
  }

  void toggleAudio() async {
    final muted = !state.isAudioMuted;
    await _engine?.muteLocalAudioStream(muted);
    state = state.copyWith(isAudioMuted: muted);
  }

  void toggleVideo() async {
    final muted = !state.isVideoMuted;
    await _engine?.muteLocalVideoStream(muted);
    state = state.copyWith(isVideoMuted: muted);
  }

  void switchCamera() async {
    await _engine?.switchCamera();
  }

  Future<void> leaveChannel() async {
    try {
      if (state.isVideoCall) {
        try { await _engine?.stopPreview(); } catch(e) {}
      }
      try { await _engine?.leaveChannel(); } catch(e) {}
      try { await _engine?.release(); } catch(e) {}
      _engine = null;
    } catch(e) {
      print("Error leaving channel overarching: $e");
    } finally {
      state = const CallState();
    }
  }
}
