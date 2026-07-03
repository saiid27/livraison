import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../constants/app_constants.dart';

enum SupportCallRole { client, admin }

class IncomingSupportCall {
  const IncomingSupportCall({
    required this.callId,
    required this.clientName,
    required this.createdAt,
  });

  final String callId;
  final String clientName;
  final DateTime createdAt;

  factory IncomingSupportCall.fromJson(Map<String, dynamic> json) {
    return IncomingSupportCall(
      callId: json['call_id'].toString(),
      clientName: json['client_name']?.toString() ?? 'Client',
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class SupportCallSession {
  SupportCallSession({
    required this.role,
    this.onStatus,
    this.onIncomingCall,
    this.onCallEnded,
  });

  final SupportCallRole role;
  final void Function(String status)? onStatus;
  final void Function(IncomingSupportCall call)? onIncomingCall;
  final void Function(String reason)? onCallEnded;

  static const _storage = FlutterSecureStorage();
  WebSocketChannel? _channel;
  RTCPeerConnection? _peer;
  MediaStream? _localStream;
  StreamSubscription? _socketSub;
  Future<void>? _connectFuture;
  String? _callId;

  bool get isInCall => _callId != null;

  Future<void> connect() async {
    if (_connectFuture != null) return _connectFuture;
    _connectFuture = _connect();
    return _connectFuture;
  }

  Future<void> _connect() async {
    final token = await _storage.read(key: AppConstants.tokenKey);
    if (token == null) {
      onStatus?.call('غير مسجل الدخول');
      return;
    }

    Object? lastError;
    for (final url in AppConstants.supportCallWsUrls) {
      try {
        final uri = Uri.parse(url).replace(queryParameters: {'token': token});
        final channel = WebSocketChannel.connect(uri);
        await channel.ready.timeout(const Duration(seconds: 14));
        _channel = channel;
        _socketSub = _channel!.stream.listen(
          _handleMessage,
          onError: (error) => onStatus?.call('تعذر الاتصال بالمركز: $error'),
          onDone: () => onStatus?.call('انقطع الاتصال بالمركز'),
        );
        lastError = null;
        break;
      } catch (error) {
        lastError = error;
      }
    }

    if (_channel == null) {
      _connectFuture = null;
      onStatus?.call('تعذر فتح اتصال المركز: ${lastError ?? ''}');
      return;
    }

    if (role == SupportCallRole.admin) {
      _send({'type': 'presence'});
    }
  }

  Future<void> startClientCall() async {
    await _ensureConnected();
    if (_channel == null) return;
    onStatus?.call('جاري الاتصال بالمركز...');
    _send({'type': 'call_start'});
  }

  Future<void> acceptCall(String callId) async {
    await _ensureConnected();
    if (_channel == null) return;
    _callId = callId;
    _send({'type': 'accept_call', 'call_id': callId});
    onStatus?.call('تم قبول المكالمة، بانتظار الصوت...');
  }

  Future<void> endCall() async {
    final callId = _callId;
    if (callId != null) {
      _send({'type': 'end_call', 'call_id': callId});
    }
    await _closePeer();
    _callId = null;
    onStatus?.call('تم إنهاء المكالمة');
  }

  Future<void> dispose() async {
    await endCall();
    await _socketSub?.cancel();
    await _channel?.sink.close();
  }

  Future<void> _ensureConnected() async {
    if (_channel == null) {
      await connect();
    }
  }

  Future<void> _handleMessage(dynamic raw) async {
    final data = _parse(raw);
    final type = data['type'];

    switch (type) {
      case 'connected':
        onStatus?.call('متصل بالمركز');
        break;
      case 'presence_ok':
        final count = data['online_admins'] ?? 0;
        onStatus?.call('متصل كمشرف. المشرفون المتصلون: $count');
        break;
      case 'incoming_call':
        onIncomingCall?.call(IncomingSupportCall.fromJson(data));
        break;
      case 'ringing':
        _callId = data['call_id']?.toString();
        onStatus?.call('يرن عند المشرفين المتصلين...');
        break;
      case 'no_admins':
        onStatus?.call(data['message']?.toString() ?? 'لا يوجد مشرف متصل');
        break;
      case 'call_accepted':
        _callId = data['call_id']?.toString();
        onStatus?.call('تم قبول المكالمة');
        if (role == SupportCallRole.client) {
          await _createPeer();
          final offer = await _peer!.createOffer();
          await _peer!.setLocalDescription(offer);
          _sendDescription('offer', offer);
        }
        break;
      case 'offer':
        await _createPeer();
        await _peer!.setRemoteDescription(
          RTCSessionDescription(
            data['sdp']?.toString(),
            data['sdp_type']?.toString(),
          ),
        );
        final answer = await _peer!.createAnswer();
        await _peer!.setLocalDescription(answer);
        _sendDescription('answer', answer);
        onStatus?.call('المكالمة الصوتية بدأت');
        break;
      case 'answer':
        await _peer?.setRemoteDescription(
          RTCSessionDescription(
            data['sdp']?.toString(),
            data['sdp_type']?.toString(),
          ),
        );
        onStatus?.call('المكالمة الصوتية بدأت');
        break;
      case 'candidate':
        final candidate = data['candidate'];
        if (_peer != null && candidate is Map) {
          await _peer!.addCandidate(
            RTCIceCandidate(
              candidate['candidate']?.toString(),
              candidate['sdpMid']?.toString(),
              candidate['sdpMLineIndex'] as int?,
            ),
          );
        }
        break;
      case 'call_taken':
        onStatus?.call('مشرف آخر استلم المكالمة');
        break;
      case 'call_unavailable':
        onStatus?.call('هذه المكالمة لم تعد متاحة');
        break;
      case 'call_ended':
        final reason = data['reason']?.toString() ?? 'ended';
        await _closePeer();
        _callId = null;
        onStatus?.call('انتهت المكالمة');
        onCallEnded?.call(reason);
        break;
      case 'unauthorized':
        onStatus?.call('غير مصرح لك بالاتصال');
        break;
    }
  }

  Future<void> _createPeer() async {
    if (_peer != null) return;

    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': false,
    });

    _peer = await createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},
      ],
    });

    for (final track in _localStream!.getAudioTracks()) {
      await _peer!.addTrack(track, _localStream!);
    }

    _peer!.onIceCandidate = (candidate) {
      if (candidate.candidate == null) return;
      _send({
        'type': 'candidate',
        'call_id': _callId,
        'candidate': candidate.toMap(),
      });
    };

    _peer!.onTrack = (event) {
      onStatus?.call('الصوت متصل');
    };
  }

  void _sendDescription(String type, RTCSessionDescription description) {
    _send({
      'type': type,
      'call_id': _callId,
      'sdp': description.sdp,
      'sdp_type': description.type,
    });
  }

  Future<void> _closePeer() async {
    for (final track in _localStream?.getTracks() ?? <MediaStreamTrack>[]) {
      await track.stop();
    }
    await _localStream?.dispose();
    _localStream = null;
    await _peer?.close();
    await _peer?.dispose();
    _peer = null;
  }

  void _send(Map<String, dynamic> payload) {
    _channel?.sink.add(jsonEncode(payload));
  }

  Map<String, dynamic> _parse(dynamic raw) {
    try {
      final decoded = jsonDecode(raw.toString());
      return decoded is Map<String, dynamic> ? decoded : {};
    } catch (_) {
      return {};
    }
  }
}
