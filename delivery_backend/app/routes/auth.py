from flask import Blueprint, request, jsonify, current_app
from flask_jwt_extended import create_access_token, jwt_required, get_jwt_identity
from app import db, bcrypt
from app.models.user import User
from pathlib import Path
from uuid import uuid4
from werkzeug.utils import secure_filename
from datetime import datetime, timedelta
from secrets import randbelow
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen
import json
import os

auth_bp = Blueprint('auth', __name__)

CAPTAIN_FILES = {
    'profile_image': 'avatar',
    'id_card_image': 'id_card_image',
    'vehicle_image': 'vehicle_image',
    'vehicle_registration_image': 'vehicle_registration_image',
    'permit_image': 'permit_image',
}

CHINGUISOFT_TIMEOUT_SECONDS = 12
CHINGUISOFT_ALLOWED_STATUSES = {200, 401, 402, 422, 429, 503}

OTP_STATUS_MESSAGES = {
    200: 'تمت العملية بنجاح',
    401: 'خدمة الرسائل غير مصرح بها. يرجى التواصل مع الدعم.',
    402: 'رصيد خدمة الرسائل غير كافٍ. يرجى التواصل مع الدعم.',
    422: 'رقم الهاتف أو رمز التحقق غير صالح.',
    429: 'طلبات كثيرة جدًا. يرجى المحاولة لاحقًا.',
    503: 'خدمة الرسائل غير متاحة حاليًا. يرجى المحاولة لاحقًا.',
}


def _otp_error(status_code):
    return jsonify({
        'message': OTP_STATUS_MESSAGES.get(
            status_code,
            'تعذر تنفيذ طلب التحقق. يرجى المحاولة لاحقًا.',
        )
    }), status_code


def _clean_otp_payload(data, require_code=False):
    phone = str(data.get('phone', '')).strip()
    lang = str(data.get('lang', 'ar')).strip() or 'ar'
    code = str(data.get('code', '')).strip()

    if not phone:
        return None, _otp_error(422)
    if require_code and not code:
        return None, _otp_error(422)

    payload = {'phone': phone, 'lang': lang}
    if require_code:
        payload['code'] = code
    return payload, None


def _call_chinguisoft_otp(payload):
    validation_key = current_app.config.get('CHINGUISOFT_VALIDATION_KEY')
    validation_token = current_app.config.get('CHINGUISOFT_VALIDATION_TOKEN')
    if not validation_key or not validation_token:
        current_app.logger.error('Chinguisoft OTP environment is not configured')
        return None, 503

    url = f'https://chinguisoft.com/api/sms/validation/{validation_key}'
    body = json.dumps(payload).encode('utf-8')
    external_request = Request(
        url,
        data=body,
        headers={
            'Validation-token': validation_token,
            'Content-Type': 'application/json',
        },
        method='POST',
    )

    try:
        with urlopen(
            external_request,
            timeout=CHINGUISOFT_TIMEOUT_SECONDS,
        ) as response:
            response.read()
            return response.status, None
    except HTTPError as error:
        error.read()
        return error.code, None
    except (TimeoutError, URLError, OSError):
        current_app.logger.warning('Chinguisoft OTP request failed')
        return None, 503


def _save_upload(upload, category):
    original = secure_filename(upload.filename or '')
    extension = Path(original).suffix.lower()
    if extension not in {'.jpg', '.jpeg', '.png', '.webp'}:
        raise ValueError('Format image non pris en charge')

    relative_dir = os.path.join('captains', category)
    target_dir = os.path.join(current_app.config['UPLOAD_FOLDER'], relative_dir)
    os.makedirs(target_dir, exist_ok=True)
    filename = f'{uuid4().hex}{extension}'
    upload.save(os.path.join(target_dir, filename))
    return f'/uploads/{relative_dir}/{filename}'


@auth_bp.route('/request-otp', methods=['POST'])
def request_otp():
    data = request.get_json(silent=True) or {}
    payload, error_response = _clean_otp_payload(data)
    if error_response:
        return error_response

    status_code, fallback_status = _call_chinguisoft_otp(payload)
    if fallback_status:
        return _otp_error(fallback_status)
    if status_code not in CHINGUISOFT_ALLOWED_STATUSES:
        current_app.logger.warning(
            'Unexpected Chinguisoft OTP request status: %s',
            status_code,
        )
        return _otp_error(503)
    if status_code != 200:
        return _otp_error(status_code)

    return jsonify({'message': 'تم إرسال رمز التحقق بنجاح'}), 200


@auth_bp.route('/verify-otp', methods=['POST'])
def verify_otp():
    data = request.get_json(silent=True) or {}
    payload, error_response = _clean_otp_payload(data, require_code=True)
    if error_response:
        return error_response

    status_code, fallback_status = _call_chinguisoft_otp(payload)
    if fallback_status:
        return _otp_error(fallback_status)
    if status_code not in CHINGUISOFT_ALLOWED_STATUSES:
        current_app.logger.warning(
            'Unexpected Chinguisoft OTP verify status: %s',
            status_code,
        )
        return _otp_error(503)
    if status_code != 200:
        return _otp_error(status_code)

    return jsonify({'message': 'تم التحقق من الرمز بنجاح'}), 200


@auth_bp.route('/register', methods=['POST'])
def register():
    data = request.form.to_dict() if request.form else (request.get_json(silent=True) or {})

    required = ['name', 'email', 'password', 'phone', 'role']
    if not all(k in data for k in required):
        return jsonify({'message': 'Champs manquants'}), 400

    if data['role'] not in ('client', 'livreur', 'car_captain', 'merchant'):
        return jsonify({'message': 'Rôle invalide'}), 400

    if User.query.filter_by(email=data['email']).first():
        return jsonify({'message': 'Email déjà utilisé'}), 409

    password_hash = bcrypt.generate_password_hash(data['password']).decode('utf-8')

    captain_images = {}
    if data['role'] in ('livreur', 'car_captain'):
        missing_files = [key for key in CAPTAIN_FILES if key not in request.files]
        if missing_files:
            return jsonify({'message': 'Toutes les photos du capitaine sont obligatoires'}), 400
        try:
            for form_key, model_key in CAPTAIN_FILES.items():
                captain_images[model_key] = _save_upload(request.files[form_key], form_key)
        except ValueError as error:
            return jsonify({'message': str(error)}), 400

    user = User(
        name=data['name'],
        email=data['email'],
        phone=data['phone'],
        password_hash=password_hash,
        role=data['role'],
        approval_status='pending' if data['role'] in ('livreur', 'car_captain') else 'approved',
        vehicle_type='car' if data['role'] == 'car_captain' else 'moto',
        **captain_images,
    )
    db.session.add(user)
    db.session.commit()

    token = create_access_token(identity=str(user.id))
    return jsonify({'token': token, 'user': user.to_dict()}), 201


@auth_bp.route('/login', methods=['POST'])
def login():
    data = request.get_json()

    if not data or 'email' not in data or 'password' not in data:
        return jsonify({'message': 'Email et mot de passe requis'}), 400

    user = User.query.filter_by(email=data['email']).first()

    if not user or not bcrypt.check_password_hash(user.password_hash, data['password']):
        return jsonify({'message': 'Email ou mot de passe incorrect'}), 401

    if not user.is_active:
        return jsonify({'message': 'Compte désactivé'}), 403

    token = create_access_token(identity=str(user.id))
    return jsonify({'token': token, 'user': user.to_dict()}), 200


@auth_bp.route('/me', methods=['GET'])
@jwt_required()
def me():
    user_id = get_jwt_identity()
    user = User.query.get(user_id)
    if not user:
        return jsonify({'message': 'Utilisateur introuvable'}), 404
    return jsonify({'user': user.to_dict()}), 200


@auth_bp.route('/forgot-password', methods=['POST'])
def forgot_password():
    data = request.get_json(silent=True) or {}
    email = str(data.get('email', '')).strip().lower()
    if not email:
        return jsonify({'message': 'Email requis'}), 400

    user = User.query.filter(db.func.lower(User.email) == email).first()
    response = {
        'message': 'Si ce compte existe, un code de réinitialisation a été envoyé.'
    }
    if user:
        code = f'{randbelow(1000000):06d}'
        user.reset_code = code
        user.reset_code_expires_at = datetime.utcnow() + timedelta(minutes=10)
        db.session.commit()

        # Development fallback until an email/SMS provider is configured.
        if os.getenv('FLASK_ENV') == 'development':
            response['dev_code'] = code

    return jsonify(response), 200


@auth_bp.route('/reset-password', methods=['POST'])
def reset_password():
    data = request.get_json(silent=True) or {}
    email = str(data.get('email', '')).strip().lower()
    code = str(data.get('code', '')).strip()
    password = str(data.get('password', ''))

    if not email or not code or not password:
        return jsonify({'message': 'Email, code et mot de passe requis'}), 400
    if len(password) < 6:
        return jsonify({'message': 'Le mot de passe doit contenir au moins 6 caractères'}), 400

    user = User.query.filter(db.func.lower(User.email) == email).first()
    if (
        not user
        or not user.reset_code
        or user.reset_code != code
        or not user.reset_code_expires_at
        or user.reset_code_expires_at < datetime.utcnow()
    ):
        return jsonify({'message': 'Code invalide ou expiré'}), 400

    user.password_hash = bcrypt.generate_password_hash(password).decode('utf-8')
    user.reset_code = None
    user.reset_code_expires_at = None
    db.session.commit()
    return jsonify({'message': 'Mot de passe mis à jour'}), 200
