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
  int remoteUid = 996; //写死 996 为远端
  final TextEditingController _controller = TextEditingController();
  int streamId = 0;
  int localUid = 0;

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
      },
      onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
        logSink.log(
            '[onJoinChannelSuccess] connection: ${connection.toJson()} elapsed: $elapsed');
        setState(() {
          isJoined = true;
          localUid = connection.localUid!;
        });
      },
      onRemoteAudioStateChanged: (RtcConnection connection, int remoteUid,
          RemoteAudioState state, RemoteAudioStateReason reason, int elapsed) {
        logSink.log(
            '[onRemoteAudioStateChanged] connection: ${connection.toJson()} remoteUid: $remoteUid RemoteAudioState: $state RemoteAudioStateReason: $reason elapsed: $elapsed');
      },
      onLeaveChannel: (RtcConnection connection, RtcStats stats) {
        logSink.log(
            '[onLeaveChannel] connection: ${connection.toJson()} stats: ${stats.toJson()}');
        setState(() {
          isJoined = false;
          remoteUid = 0;
        });
      },
      onStreamMessageError: (RtcConnection connection, int remoteUid,
          int streamId, ErrorCodeType code, int missed, int cached) {
        logSink.log(
            '[onStreamMessageError] connection: ${connection.toJson()} remoteUid: $remoteUid, streamId: $streamId, code: $code, missed: $missed, cached: $cached');
      },
    ));
    await _engine
        .setSubscribeAudioAllowlist(uidList: [996, 999, 2024], uidNumber: 3);
    await _engine.joinChannel(
        token: config.token,
        channelId: config.channelId,
        uid: 0,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          publishCameraTrack: false,
          publishMicrophoneTrack: false,
          autoSubscribeAudio: false,
          autoSubscribeVideo: true,
        ));

    streamId = await _engine.createDataStream(
        const DataStreamConfig(syncWithAudio: false, ordered: true));
  }

  Future<void> _onPressSend() async {
    if (_controller.text.isEmpty) {
      return;
    }
    var messageMap = {
      "name": "$localUid",
      "type": "audience",
      "message": _controller.text
    };
    String messageData = jsonEncode(messageMap);

    try {
      final data = Uint8List.fromList(utf8.encode(messageData));
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
      body: Stack(
        children: [
          AgoraVideoView(
            controller: VideoViewController(
              rtcEngine: _engine,
              canvas: VideoCanvas(
                  uid: remoteUid, renderMode: RenderModeType.renderModeFit),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              if (isJoined)
                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        flex: 4,
                        child: TextField(
                          style: const TextStyle(color: Colors.white),
                          controller: _controller,
                          decoration: const InputDecoration(
                            hintText: '说点什么',
                            hintStyle: TextStyle(color: Colors.white),

                            // 设置未聚焦状态的边框颜色
                            enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(50.0)),
                              borderSide:
                                  BorderSide(color: Colors.grey), // 边框颜色为灰色
                            ),
                            // 设置聚焦状态的边框颜色
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(50.0)),
                              borderSide: BorderSide(
                                  color: Colors.deepPurple), // 边框颜色为灰色
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: IconButton(
                          onPressed: _onPressSend,
                          icon: const Icon(
                            Icons.send,
                            color: Colors.purple,
                          ),
                        ),
                      ),
                      Expanded(flex: 5, child: Container()),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
