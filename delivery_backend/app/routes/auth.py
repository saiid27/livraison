from flask import Blueprint, request, jsonify, current_app, send_file
from flask_jwt_extended import create_access_token, jwt_required, get_jwt_identity
from app import db, bcrypt
from app.models.user import User
from app.models.account_deletion_request import AccountDeletionRequest
from sqlalchemy import text
from pathlib import Path
from uuid import uuid4
from werkzeug.utils import secure_filename
from datetime import datetime, timedelta
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen
from io import BytesIO
import json
import os

auth_bp = Blueprint('auth', __name__)

CAPTAIN_FILES = {
    'profile_image': ('avatar', 'avatar_data', 'avatar_mime'),
    'id_card_image': ('id_card_image', 'id_card_image_data', 'id_card_image_mime'),
    'vehicle_image': ('vehicle_image', 'vehicle_image_data', 'vehicle_image_mime'),
    'vehicle_registration_image': (
        'vehicle_registration_image',
        'vehicle_registration_image_data',
        'vehicle_registration_image_mime',
    ),
    'permit_image': ('permit_image', 'permit_image_data', 'permit_image_mime'),
}

IMAGE_FIELDS = {
    'avatar': ('avatar_data', 'avatar_mime'),
    'id_card_image': ('id_card_image_data', 'id_card_image_mime'),
    'vehicle_image': ('vehicle_image_data', 'vehicle_image_mime'),
    'vehicle_registration_image': (
        'vehicle_registration_image_data',
        'vehicle_registration_image_mime',
    ),
    'permit_image': ('permit_image_data', 'permit_image_mime'),
}

IMAGE_MIME_BY_EXTENSION = {
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.png': 'image/png',
    '.webp': 'image/webp',
}

CHINGUISOFT_TIMEOUT_SECONDS = 12
CHINGUISOFT_ALLOWED_STATUSES = {200, 401, 402, 422, 429, 503}
OTP_RESEND_COOLDOWN = timedelta(seconds=60)
OTP_VERIFY_WINDOW = timedelta(minutes=10)

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


def _request_id():
    return uuid4().hex


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


def _reserve_otp_send(phone, request_id):
    now = datetime.utcnow()
    cutoff = now - OTP_RESEND_COOLDOWN
    result = db.session.execute(
        text(
            """
            INSERT INTO otp_rate_limits (phone, requested_at)
            VALUES (:phone, :now)
            ON CONFLICT (phone) DO UPDATE
            SET requested_at = EXCLUDED.requested_at
            WHERE otp_rate_limits.requested_at <= :cutoff
            RETURNING requested_at
            """
        ),
        {'phone': phone, 'now': now, 'cutoff': cutoff},
    ).first()
    db.session.commit()

    current_app.logger.info(
        'OTP send reservation request_id=%s phone=%s timestamp=%s allowed=%s',
        request_id,
        phone,
        now.isoformat(),
        result is not None,
    )

    if result is not None:
        return True, 0

    existing = db.session.execute(
        text("SELECT requested_at FROM otp_rate_limits WHERE phone = :phone"),
        {'phone': phone},
    ).first()
    remaining_seconds = int(OTP_RESEND_COOLDOWN.total_seconds())
    if existing and existing[0]:
        next_allowed_at = existing[0] + OTP_RESEND_COOLDOWN
        remaining_seconds = max(
            1,
            int((next_allowed_at - now).total_seconds()),
        )
    return False, remaining_seconds


def _otp_already_sent(remaining_seconds, request_id):
    return jsonify({
        'message': 'OTP already sent. Please wait before requesting again.',
        'remaining_seconds': remaining_seconds,
        'request_id': request_id,
    }), 429


def _call_chinguisoft_otp(payload, purpose, request_id):
    validation_key = current_app.config.get('CHINGUISOFT_VALIDATION_KEY')
    validation_token = current_app.config.get('CHINGUISOFT_VALIDATION_TOKEN')
    if not validation_key or not validation_token:
        current_app.logger.error('Chinguisoft OTP environment is not configured')
        return None, 503

    phone = str(payload.get('phone', ''))
    current_app.logger.info(
        'Chinguisoft OTP call request_id=%s purpose=%s phone=%s timestamp=%s has_code=%s',
        request_id,
        purpose,
        phone,
        datetime.utcnow().isoformat(),
        'code' in payload,
    )

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
        current_app.logger.warning(
            'Chinguisoft OTP request failed request_id=%s phone=%s',
            request_id,
            phone,
        )
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


def _read_upload_image(upload):
    original = secure_filename(upload.filename or '')
    extension = Path(original).suffix.lower()
    mime_type = IMAGE_MIME_BY_EXTENSION.get(extension)
    if not mime_type:
        raise ValueError('Format image non pris en charge')

    image_data = upload.read()
    if not image_data:
        raise ValueError('Image vide')
    return image_data, mime_type


def _generated_email(phone):
    digits = ''.join(ch for ch in phone if ch.isdigit())
    return f'{digits or uuid4().hex}@phone.mayahsar.local'


@auth_bp.route('/images/<int:user_id>/<field>', methods=['GET'])
def user_image(user_id, field):
    if field not in IMAGE_FIELDS:
        return jsonify({'message': 'Image introuvable'}), 404

    user = User.query.get(user_id)
    if not user:
        return jsonify({'message': 'Utilisateur introuvable'}), 404

    data_attr, mime_attr = IMAGE_FIELDS[field]
    image_data = getattr(user, data_attr)
    if not image_data:
        return jsonify({'message': 'Image introuvable'}), 404

    return send_file(
        BytesIO(image_data),
        mimetype=getattr(user, mime_attr) or 'image/jpeg',
        max_age=86400,
    )


@auth_bp.route('/request-otp', methods=['POST'])
def request_otp():
    data = request.get_json(silent=True) or {}
    payload, error_response = _clean_otp_payload(data)
    if error_response:
        return error_response

    request_id = _request_id()
    allowed, remaining_seconds = _reserve_otp_send(payload['phone'], request_id)
    if not allowed:
        return _otp_already_sent(remaining_seconds, request_id)

    status_code, fallback_status = _call_chinguisoft_otp(
        payload,
        'request-otp',
        request_id,
    )
    if fallback_status:
        return _otp_error(fallback_status)
    if status_code not in CHINGUISOFT_ALLOWED_STATUSES:
        current_app.logger.warning(
            'Unexpected Chinguisoft OTP request status: %s request_id=%s',
            status_code,
            request_id,
        )
        return _otp_error(503)
    if status_code != 200:
        return _otp_error(status_code)

    return jsonify({
        'message': 'تم إرسال رمز التحقق بنجاح',
        'request_id': request_id,
    }), 200


@auth_bp.route('/verify-otp', methods=['POST'])
def verify_otp():
    data = request.get_json(silent=True) or {}
    payload, error_response = _clean_otp_payload(data, require_code=True)
    if error_response:
        return error_response

    request_id = _request_id()
    status_code, fallback_status = _call_chinguisoft_otp(
        payload,
        'verify-otp',
        request_id,
    )
    if fallback_status:
        return _otp_error(fallback_status)
    if status_code not in CHINGUISOFT_ALLOWED_STATUSES:
        current_app.logger.warning(
            'Unexpected Chinguisoft OTP verify status: %s request_id=%s',
            status_code,
            request_id,
        )
        return _otp_error(503)
    if status_code != 200:
        return _otp_error(status_code)

    user = User.query.filter_by(phone=payload['phone']).first()
    if user:
        user.otp_verified_at = datetime.utcnow()
        db.session.commit()

    return jsonify({'message': 'تم التحقق من الرمز بنجاح'}), 200


@auth_bp.route('/register', methods=['POST'])
def register():
    data = request.form.to_dict() if request.form else (request.get_json(silent=True) or {})

    required = ['name', 'password', 'phone', 'role']
    if not all(k in data for k in required):
        return jsonify({'message': 'Champs manquants'}), 400

    if data['role'] not in ('client', 'livreur', 'merchant'):
        return jsonify({'message': 'Rôle invalide'}), 400

    phone = str(data['phone']).strip()
    if User.query.filter_by(phone=phone).first():
        return jsonify({'message': 'رقم الهاتف مستخدم بالفعل'}), 409

    email = str(data.get('email') or '').strip().lower() or _generated_email(phone)
    if User.query.filter(db.func.lower(User.email) == email).first():
        return jsonify({'message': 'بيانات الحساب مستخدمة بالفعل'}), 409

    password_hash = bcrypt.generate_password_hash(data['password']).decode('utf-8')

    captain_images = {}
    if data['role'] in ('livreur', 'car_captain'):
        missing_files = [key for key in CAPTAIN_FILES if key not in request.files]
        if missing_files:
            return jsonify({'message': 'Toutes les photos du capitaine sont obligatoires'}), 400
        try:
            for form_key, (path_key, data_key, mime_key) in CAPTAIN_FILES.items():
                image_data, mime_type = _read_upload_image(request.files[form_key])
                captain_images[path_key] = 'stored_in_database'
                captain_images[data_key] = image_data
                captain_images[mime_key] = mime_type
        except ValueError as error:
            return jsonify({'message': str(error)}), 400

    merchant_images = {}
    if data['role'] == 'merchant':
        if 'profile_image' not in request.files or not request.files['profile_image'].filename:
            return jsonify({'message': 'صورة المؤسسة إلزامية'}), 400
        try:
            merchant_images['avatar'] = _save_upload(
                request.files['profile_image'],
                'merchant_profiles',
            )
        except ValueError as error:
            return jsonify({'message': str(error)}), 400

    user = User(
        name=data['name'],
        email=email,
        phone=phone,
        password_hash=password_hash,
        role=data['role'],
        approval_status='pending' if data['role'] in ('livreur', 'car_captain') else 'approved',
        vehicle_type='car' if data['role'] == 'car_captain' else 'moto',
        **captain_images,
        **merchant_images,
    )
    db.session.add(user)
    db.session.flush()
    if data['role'] in ('livreur', 'car_captain'):
        for _, (path_key, _, _) in CAPTAIN_FILES.items():
            setattr(user, path_key, f'/api/auth/images/{user.id}/{path_key}')
    db.session.commit()

    token = create_access_token(identity=str(user.id))
    return jsonify({'token': token, 'user': user.to_dict()}), 201


@auth_bp.route('/login', methods=['POST'])
def login():
    data = request.get_json()

    if not data or 'phone' not in data or 'password' not in data:
        return jsonify({'message': 'رقم الهاتف وكلمة المرور مطلوبان'}), 400

    phone = str(data['phone']).strip()
    user = User.query.filter_by(phone=phone).first()

    if not user or not bcrypt.check_password_hash(user.password_hash, data['password']):
        return jsonify({'message': 'رقم الهاتف أو كلمة المرور غير صحيحة'}), 401

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
    payload, error_response = _clean_otp_payload(data)
    if error_response:
        return error_response

    now = datetime.utcnow()
    user = User.query.filter_by(phone=payload['phone']).first()
    if not user:
        return jsonify({'message': 'لا يوجد حساب بهذا الرقم'}), 404

    request_id = _request_id()
    allowed, remaining_seconds = _reserve_otp_send(payload['phone'], request_id)
    if not allowed:
        return _otp_already_sent(remaining_seconds, request_id)

    status_code, fallback_status = _call_chinguisoft_otp(
        payload,
        'forgot-password',
        request_id,
    )
    if fallback_status:
        return _otp_error(fallback_status)
    if status_code not in CHINGUISOFT_ALLOWED_STATUSES:
        current_app.logger.warning(
            'Unexpected Chinguisoft password reset status: %s request_id=%s',
            status_code,
            request_id,
        )
        return _otp_error(503)
    if status_code != 200:
        return _otp_error(status_code)

    user.otp_requested_at = now
    user.otp_verified_at = None
    db.session.commit()

    return jsonify({
        'message': 'تم إرسال رمز التحقق بنجاح',
        'request_id': request_id,
        'user': {'name': user.name, 'phone': user.phone},
    }), 200


@auth_bp.route('/reset-password', methods=['POST'])
def reset_password():
    data = request.get_json(silent=True) or {}
    phone = str(data.get('phone', '')).strip()
    password = str(data.get('password', ''))

    if not phone or not password:
        return jsonify({'message': 'رقم الهاتف وكلمة المرور مطلوبة'}), 400
    if len(password) < 6:
        return jsonify({'message': 'كلمة المرور يجب أن تحتوي على 6 أحرف على الأقل'}), 400

    user = User.query.filter_by(phone=phone).first()
    if not user:
        return jsonify({'message': 'لا يوجد حساب بهذا الرقم'}), 404

    if (
        not user.otp_verified_at
        or user.otp_verified_at + OTP_VERIFY_WINDOW < datetime.utcnow()
    ):
        return jsonify({'message': 'يرجى التحقق من رمز OTP أولًا'}), 422

    user.password_hash = bcrypt.generate_password_hash(password).decode('utf-8')
    user.otp_requested_at = None
    user.otp_verified_at = None
    db.session.commit()
    return jsonify({'message': 'تم تغيير كلمة المرور بنجاح'}), 200


@auth_bp.route('/change-password', methods=['PUT'])
@jwt_required()
def change_password():
    user = User.query.get(get_jwt_identity())
    if not user:
        return jsonify({'message': 'Utilisateur introuvable'}), 404

    data = request.get_json(silent=True) or {}
    current_password = str(data.get('current_password', ''))
    new_password = str(data.get('new_password', ''))

    if not current_password or not new_password:
        return jsonify({'message': 'كلمة المرور الحالية والجديدة مطلوبة'}), 400
    if len(new_password) < 6:
        return jsonify({'message': 'كلمة المرور يجب أن تحتوي على 6 أحرف على الأقل'}), 400
    if not bcrypt.check_password_hash(user.password_hash, current_password):
        return jsonify({'message': 'كلمة المرور الحالية غير صحيحة'}), 401

    user.password_hash = bcrypt.generate_password_hash(new_password).decode('utf-8')
    db.session.commit()
    return jsonify({'message': 'تم تغيير كلمة المرور بنجاح'}), 200


@auth_bp.route('/account-deletion-requests', methods=['POST'])
def request_account_deletion():
    data = request.get_json(silent=True) or {}
    phone = str(data.get('phone', '')).strip()
    reason = str(data.get('reason', '')).strip()

    if not phone:
        return jsonify({'message': 'رقم الهاتف مطلوب'}), 400
    if not reason:
        return jsonify({'message': 'سبب طلب حذف الحساب مطلوب'}), 400

    user = User.query.filter_by(phone=phone).first()
    if not user:
        return jsonify({'message': 'لا يوجد حساب بهذا الرقم'}), 404

    existing = AccountDeletionRequest.query.filter_by(
        phone=phone,
        status='pending',
    ).first()
    if existing:
        return jsonify({'message': 'لديك طلب حذف حساب قيد المراجعة بالفعل'}), 409

    deletion_request = AccountDeletionRequest(
        user_id=user.id,
        user_name=user.name,
        phone=user.phone,
        role=user.role,
        reason=reason,
    )
    db.session.add(deletion_request)
    db.session.commit()

    return jsonify({
        'request': deletion_request.to_dict(),
        'message': 'تم إرسال طلب حذف الحساب إلى الإدارة',
    }), 201


@auth_bp.route('/account-deletion-requests/check-phone', methods=['POST'])
def check_account_deletion_phone():
    data = request.get_json(silent=True) or {}
    phone = str(data.get('phone', '')).strip()

    if not phone:
        return jsonify({'message': 'رقم الهاتف مطلوب'}), 400

    user = User.query.filter_by(phone=phone).first()
    if not user:
        return jsonify({'message': 'لا يوجد حساب بهذا الرقم'}), 404

    existing = AccountDeletionRequest.query.filter_by(
        phone=phone,
        status='pending',
    ).first()
    if existing:
        return jsonify({'message': 'لديك طلب حذف حساب قيد المراجعة بالفعل'}), 409

    return jsonify({
        'user': {
            'name': user.name,
            'phone': user.phone,
            'role': user.role,
        },
        'message': 'تم التحقق من وجود الحساب',
    }), 200
