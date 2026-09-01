import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LiveScreen extends StatefulWidget {
  final String channelName;
  final bool isHost;

  const LiveScreen({super.key, required this.channelName, this.isHost = false});

  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
  static const String _appId = 'YOUR_AGORA_APP_ID';
  RtcEngine? _engine;
  bool _joined = false;
  bool _muted = false;
  bool _videoOff = false;
  int? _remoteUid;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  Future<void> _initAgora() async {
    final cam = await Permission.camera.request();
    final mic = await Permission.microphone.request();
    if (!cam.isGranted || !mic.isGranted) {
      setState(() => _error = 'Camera and microphone permission required');
      return;
    }

    try {
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(const RtcEngineContext(appId: _appId));
      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (connection, elapsed) {
            setState(() => _joined = true);
            _saveLiveSession(true);
          },
          onUserJoined: (connection, remoteUid, elapsed) {
            setState(() => _remoteUid = remoteUid);
          },
          onUserOffline: (connection, remoteUid, reason) {
            setState(() => _remoteUid = null);
          },
          onError: (err, msg) {
            setState(() => _error = 'Agora error: $err');
          },
        ),
      );
      await _engine!.enableVideo();
      await _engine!.startPreview();
      await _engine!.joinChannel(
        token: '',
        channelId: widget.channelName,
        uid: 0,
        options: ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
          clientRoleType: widget.isHost
              ? ClientRoleType.clientRoleBroadcaster
              : ClientRoleType.clientRoleAudience,
        ),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _saveLiveSession(bool live) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !widget.isHost) return;
    await FirebaseFirestore.instance.collection('live_sessions').doc(widget.channelName).set({
      'channelName': widget.channelName,
      'hostId': user.uid,
      'isLive': live,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _leave() async {
    await _saveLiveSession(false);
    await _engine?.leaveChannel();
    await _engine?.release();
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _engine?.leaveChannel();
    _engine?.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
              ),
            )
          else if (!_joined)
            const Center(child: CircularProgressIndicator())
          else
            _buildVideoView(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('LIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        )),
                  ),
                  const SizedBox(width: 10),
                  Text(widget.channelName, style: const TextStyle(color: Colors.white70)),
                  const Spacer(),
                  IconButton(
                    onPressed: _leave,
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          if (widget.isHost)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _roundButton(
                    icon: _muted ? Icons.mic_off : Icons.mic,
                    onTap: () async {
                      setState(() => _muted = !_muted);
                      await _engine?.muteLocalAudioStream(_muted);
                    },
                  ),
                  const SizedBox(width: 20),
                  _roundButton(
                    icon: _videoOff ? Icons.videocam_off : Icons.videocam,
                    onTap: () async {
                      setState(() => _videoOff = !_videoOff);
                      await _engine?.muteLocalVideoStream(_videoOff);
                    },
                  ),
                  const SizedBox(width: 20),
                  _roundButton(
                    icon: Icons.call_end,
                    color: Colors.red,
                    onTap: _leave,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoView() {
    if (widget.isHost) {
      return AgoraVideoView(
        controller: VideoViewController(
          rtcEngine: _engine!,
          canvas: const VideoCanvas(uid: 0),
        ),
      );
    }
    if (_remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine!,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: RtcConnection(channelId: widget.channelName),
        ),
      );
    }
    return const Center(
      child: Text('Waiting for host...', style: TextStyle(color: Colors.white70)),
    );
  }

  Widget _roundButton({
    required IconData icon,
    required VoidCallback onTap,
    Color color = Colors.white24,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}