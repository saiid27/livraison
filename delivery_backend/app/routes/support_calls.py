import json
from datetime import datetime, timezone
from threading import RLock
from uuid import uuid4

from flask import request
from flask_jwt_extended import decode_token

from app.models.user import User


_lock = RLock()
_admins = {}
_clients = {}
_calls = {}


def _send(ws, payload):
    try:
        ws.send(json.dumps(payload))
        return True
    except Exception:
        return False


def _safe_json(raw):
    try:
        data = json.loads(raw)
        return data if isinstance(data, dict) else {}
    except Exception:
        return {}


def _user_from_token(token):
    if not token:
        return None
    try:
        decoded = decode_token(token)
        user_id = decoded.get('sub')
        return User.query.get(int(user_id))
    except Exception:
        return None


def _admin_count():
    with _lock:
        return len(_admins)


def _call_public_payload(call):
    return {
        'type': 'incoming_call',
        'call_id': call['id'],
        'client_id': call['client_id'],
        'client_name': call['client_name'],
        'created_at': call['created_at'],
    }


def _cleanup_call(call_id, reason='ended'):
    with _lock:
        call = _calls.pop(call_id, None)
    if not call:
        return

    payload = {'type': 'call_ended', 'call_id': call_id, 'reason': reason}
    if call.get('client_ws'):
        _send(call['client_ws'], payload)
    if call.get('admin_ws'):
        _send(call['admin_ws'], payload)


def _handle_client_message(ws, user, data):
    message_type = data.get('type')

    if message_type == 'call_start':
        call_id = uuid4().hex
        call = {
            'id': call_id,
            'client_id': user.id,
            'client_name': user.name or user.phone,
            'client_ws': ws,
            'admin_ws': None,
            'status': 'ringing',
            'created_at': datetime.now(timezone.utc).isoformat(),
        }
        with _lock:
            _calls[call_id] = call
            admins = list(_admins.values())

        if not admins:
            _send(ws, {'type': 'no_admins', 'message': 'لا يوجد مشرف متصل الآن'})
            _cleanup_call(call_id, reason='no_admins')
            return

        _send(ws, {'type': 'ringing', 'call_id': call_id, 'admins': len(admins)})
        for admin in admins:
            _send(admin['ws'], _call_public_payload(call))
        return

    if message_type in {'offer', 'answer', 'candidate'}:
        call_id = data.get('call_id')
        with _lock:
            call = _calls.get(call_id)
        if call and call.get('admin_ws'):
            _send(call['admin_ws'], data)
        return

    if message_type == 'end_call':
        _cleanup_call(data.get('call_id'), reason='client_ended')


def _handle_admin_message(ws, user, data):
    message_type = data.get('type')

    if message_type == 'presence':
        _send(ws, {'type': 'presence_ok', 'online_admins': _admin_count()})
        with _lock:
            ringing_calls = [
                _call_public_payload(call)
                for call in _calls.values()
                if call.get('status') == 'ringing'
            ]
        for payload in ringing_calls:
            _send(ws, payload)
        return

    if message_type == 'accept_call':
        call_id = data.get('call_id')
        with _lock:
            call = _calls.get(call_id)
            if not call or call.get('status') != 'ringing':
                call = None
            else:
                call['status'] = 'accepted'
                call['admin_id'] = user.id
                call['admin_name'] = user.name or user.phone
                call['admin_ws'] = ws
                admins = list(_admins.values())

        if not call:
            _send(ws, {'type': 'call_unavailable', 'call_id': call_id})
            return

        accepted_payload = {
            'type': 'call_accepted',
            'call_id': call_id,
            'admin_id': user.id,
            'admin_name': user.name or user.phone,
        }
        _send(ws, accepted_payload)
        _send(call['client_ws'], accepted_payload)
        for admin in admins:
            if admin['ws'] is not ws:
                _send(admin['ws'], {'type': 'call_taken', 'call_id': call_id})
        return

    if message_type in {'offer', 'answer', 'candidate'}:
        call_id = data.get('call_id')
        with _lock:
            call = _calls.get(call_id)
        if call and call.get('client_ws'):
            _send(call['client_ws'], data)
        return

    if message_type == 'end_call':
        _cleanup_call(data.get('call_id'), reason='admin_ended')


def register_support_call_routes(sock):
    @sock.route('/api/ws/support-calls')
    @sock.route('/ws/support-calls')
    def support_calls(ws):
        token = request.args.get('token')
        user = _user_from_token(token)
        if not user or user.role not in {'client', 'admin'}:
            _send(ws, {'type': 'unauthorized'})
            ws.close()
            return

        with _lock:
            if user.role == 'admin':
                _admins[user.id] = {'ws': ws, 'user': user}
            else:
                _clients[user.id] = {'ws': ws, 'user': user}

        _send(ws, {'type': 'connected', 'role': user.role})
        if user.role == 'admin':
            _handle_admin_message(ws, user, {'type': 'presence'})

        try:
            while True:
                raw = ws.receive()
                if raw is None:
                    break
                data = _safe_json(raw)
                if user.role == 'admin':
                    _handle_admin_message(ws, user, data)
                else:
                    _handle_client_message(ws, user, data)
        finally:
            with _lock:
                if user.role == 'admin':
                    _admins.pop(user.id, None)
                else:
                    _clients.pop(user.id, None)
                call_ids = [
                    call_id
                    for call_id, call in _calls.items()
                    if call.get('client_ws') is ws or call.get('admin_ws') is ws
                ]
            for call_id in call_ids:
                _cleanup_call(call_id, reason='disconnected')
