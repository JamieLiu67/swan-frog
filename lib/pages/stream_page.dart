import 'dart:convert';
import 'dart:typed_data';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:swan_frog/config/agora.config.dart' as config;
import 'package:swan_frog/components/log_sink.dart';
import 'package:flutter/material.dart';

/// StreamMessage Example
class SendMetadata extends StatefulWidget {
  /// Construct the [StreamMessage]
  const SendMetadata({super.key});

  @override
  State<StatefulWidget> createState() => _State();
}

class _State extends State<SendMetadata> {
  late final RtcEngine _engine;
  bool isJoined = false;
  Set<int> remoteUids = {};
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initEngine();
  }

  @override
  void dispose() {
    super.dispose();

    _dispose();
  }

  Future<void> _dispose() async {
    _engine.release();
  }

  void _initEngine() async {
    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(
      appId: config.appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    _engine.registerEventHandler(RtcEngineEventHandler(
      onError: (ErrorCodeType err, String msg) {
        logSink.log('[onError] err: $err, msg: $msg');
      },
      onUserJoined: (RtcConnection connection, int rUid, int elapsed) {
        logSink.log(
            '[onUserJoined] connection: ${connection.toJson()} remoteUid: $rUid elapsed: $elapsed');
        setState(() {
          remoteUids.add(rUid);
        });
      },
      onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
        logSink.log(
            '[onJoinChannelSuccess] connection: ${connection.toJson()} elapsed: $elapsed');
        setState(() {
          isJoined = true;
        });
      },
      onLeaveChannel: (RtcConnection connection, RtcStats stats) {
        logSink.log(
            '[onLeaveChannel] connection: ${connection.toJson()} stats: ${stats.toJson()}');
        setState(() {
          isJoined = false;
        });
      },
      onStreamMessageError: (RtcConnection connection, int remoteUid,
          int streamId, ErrorCodeType code, int missed, int cached) {
        logSink.log(
            '[onStreamMessageError] connection: ${connection.toJson()} remoteUid: $remoteUid, streamId: $streamId, code: $code, missed: $missed, cached: $cached');
      },
    ));
    await _engine.joinChannel(
        token: config.token,
        channelId: config.channelId,
        uid: 997,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          publishCameraTrack: false,
          publishMicrophoneTrack: false,
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
        ));
  }

  void _joinChannel() async {
    await _engine.joinChannel(
        token: config.token,
        channelId: config.channelId,
        uid: config.uid,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          publishCameraTrack: true,
          publishMicrophoneTrack: false,
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
        ));
  }

  Future<void> _leaveChannel() async {
    await _engine.leaveChannel();
  }

  Future<void> _onPressSend() async {
    if (_controller.text.isEmpty) {
      return;
    }

    try {
      final streamId = await _engine.createDataStream(
          const DataStreamConfig(syncWithAudio: false, ordered: true));
      final data = Uint8List.fromList(utf8.encode(_controller.text));
      await _engine.sendStreamMessage(
          streamId: streamId, data: data, length: data.length);
      _controller.clear();
    } catch (e) {
      logSink.log('sendStreamMessage error: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: remoteUids.isEmpty
          ? const Center(child: Text('No remote user right now'))
          : Stack(
              children: [
                AgoraVideoView(
                  controller: VideoViewController(
                    rtcEngine: _engine,
                    canvas: const VideoCanvas(uid: 996),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: ElevatedButton(
                            onPressed: isJoined ? _leaveChannel : _joinChannel,
                            child:
                                Text('${isJoined ? 'Leave' : 'Join'} channel'),
                          ),
                        ),
                      ],
                    ),
                    if (isJoined)
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              decoration: const InputDecoration(
                                hintText: 'Input Message',
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _onPressSend,
                            child: const Text('Send'),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
    );
  }
}
