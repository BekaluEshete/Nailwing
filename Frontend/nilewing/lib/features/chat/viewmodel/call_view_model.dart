import 'package:flutter/foundation.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:nilewing/features/chat/viewModel/call_state.dart';
import 'package:nilewing/features/chat/viewmodel/chat_view_model.dart';

final callViewModelProvider =
    StateNotifierProvider<CallViewModel, CallState>((ref) {
  return CallViewModel(ref);
});

class CallViewModel extends StateNotifier<CallState> {
  final Ref _ref;
  RtcEngine? _engine;
  final String appId = "34bd620afe6f4ccd92f7d6715a0e3b21";

  CallViewModel(this._ref) : super(const CallState());

  RtcEngine? get engine => _engine;

  Future<void> initAgoraAndJoinChannel({
    required String channelName,
    required bool isVideoCall,
    required String contactId,
  }) async {
    // Request permissions
    if (!kIsWeb) {
      await [Permission.microphone, Permission.camera].request();
    }

    // Create RTC engine instance
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
          state = state.copyWith(remoteUid: remoteUid);
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          state = state.copyWith(remoteUid: null);
          // If the remote user leaves, we should probably end the call after a small delay
          if (reason == UserOfflineReasonType.userOfflineQuit) {
            leaveChannel();
          }
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
      token: "", // appId is enough for testing mode
      channelId: channelName,
      uid: 0,
      options: ChannelMediaOptions(
        autoSubscribeAudio: true,
        autoSubscribeVideo: true,
        publishCameraTrack: isVideoCall,
        publishMicrophoneTrack: true,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );

    // Send call signaling via WebSocket (Outgoing Call)
    _sendCallSignal('offer', isVideoCall);
  }

  void _sendCallSignal(String type, bool isVideoCall) async {
    try {
      // Use ChatViewModel to send the signal via existing WebSocket connection
      _ref.read(chatViewModelProvider.notifier).sendCallSignal(type, isVideoCall);
    } catch (e) {
      print("Error sending call signal: $e");
    }
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

  void setSpeakerphone(bool enabled) async {
    await _engine?.setEnableSpeakerphone(enabled);
  }

  Future<void> leaveChannel() async {
    try {
      // Send hangup signal before leaving
      _sendCallSignal('hangup', state.isVideoCall);
      
      if (state.isVideoCall) {
        try { await _engine?.stopPreview(); } catch(e) {}
      }
      try { await _engine?.leaveChannel(); } catch(e) {}
      try { await _engine?.release(); } catch(e) {}
      _engine = null;
    } catch(e) {
      print("Error leaving channel: $e");
    } finally {
      state = const CallState();
    }
  }
}
