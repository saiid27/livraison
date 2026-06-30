from flask import Blueprint, request, jsonify, current_app
from flask_jwt_extended import jwt_required
from pathlib import Path
from uuid import uuid4
from werkzeug.utils import secure_filename
import os

from app import db
from app.models.order import Order
from app.models.user import User
from app.models.payment_method import PaymentMethod
from app.models.recharge_request import RechargeRequest
from app.utils.decorators import role_required

admin_bp = Blueprint('admin', __name__)

_ALLOWED_EXTS = {'.jpg', '.jpeg', '.png', '.webp'}


def _save_upload(upload, subfolder):
    original = secure_filename(upload.filename or '')
    ext = Path(original).suffix.lower()
    if ext not in _ALLOWED_EXTS:
        raise ValueError('Format image non pris en charge')
    target_dir = os.path.join(current_app.config['UPLOAD_FOLDER'], subfolder)
    os.makedirs(target_dir, exist_ok=True)
    filename = f'{uuid4().hex}{ext}'
    upload.save(os.path.join(target_dir, filename))
    return f'/uploads/{subfolder}/{filename}'


# ── Dashboard ─────────────────────────────────────────────────────────────────

@admin_bp.route('/dashboard', methods=['GET'])
@jwt_required()
@role_required('admin')
def dashboard():
    stats = {
        'total_orders': Order.query.count(),
        'pending_orders': Order.query.filter_by(status='en_attente').count(),
        'active_orders': Order.query.filter_by(status='en_cours').count(),
        'delivered_orders': Order.query.filter_by(status='livre').count(),
        'cancelled_orders': Order.query.filter_by(status='annule').count(),
        'total_clients': User.query.filter_by(role='client').count(),
        'total_livreurs': User.query.filter_by(role='livreur').count(),
        'pending_captains': User.query.filter_by(role='livreur', approval_status='pending').count(),
        'total_merchants': User.query.filter_by(role='merchant').count(),
        'total_users': User.query.count(),
        'pending_recharges': RechargeRequest.query.filter_by(status='en_attente').count(),
    }
    return jsonify({'stats': stats}), 200


# ── Orders ────────────────────────────────────────────────────────────────────

@admin_bp.route('/orders', methods=['GET'])
@jwt_required()
@role_required('admin')
def get_all_orders():
    status = request.args.get('status')
    query = Order.query
    if status:
        query = query.filter_by(status=status)
    orders = query.order_by(Order.created_at.desc()).all()
    return jsonify({'orders': [o.to_dict() for o in orders]}), 200


@admin_bp.route('/orders/<int:order_id>/status', methods=['PUT'])
@jwt_required()
@role_required('admin')
def update_order_status(order_id):
    order = Order.query.get(order_id)
    if not order:
        return jsonify({'message': 'Commande introuvable'}), 404

    data = request.get_json()
    new_status = data.get('status')
    valid_statuses = ['en_attente', 'en_cours', 'livre', 'annule']

    if new_status not in valid_statuses:
        return jsonify({'message': 'Statut invalide'}), 400

    order.status = new_status
    db.session.commit()
    return jsonify({'order': order.to_dict(), 'message': 'Statut mis à jour'}), 200


# ── Users ─────────────────────────────────────────────────────────────────────

@admin_bp.route('/users', methods=['GET'])
@jwt_required()
@role_required('admin')
def get_all_users():
    role = request.args.get('role')
    query = User.query
    if role:
        query = query.filter_by(role=role)
    users = query.order_by(User.created_at.desc()).all()
    return jsonify({'users': [u.to_dict() for u in users]}), 200


@admin_bp.route('/users/<int:user_id>/toggle', methods=['PUT'])
@jwt_required()
@role_required('admin')
def toggle_user(user_id):
    user = User.query.get(user_id)
    if not user:
        return jsonify({'message': 'Utilisateur introuvable'}), 404

    user.is_active = not user.is_active
    db.session.commit()
    action = 'activé' if user.is_active else 'désactivé'
    return jsonify({'user': user.to_dict(), 'message': f'Utilisateur {action}'}), 200


@admin_bp.route('/captains/pending', methods=['GET'])
@jwt_required()
@role_required('admin')
def pending_captains():
    captains = User.query.filter_by(
        role='livreur', approval_status='pending'
    ).order_by(User.created_at.asc()).all()
    return jsonify({'users': [user.to_dict() for user in captains]}), 200


@admin_bp.route('/captains/<int:user_id>/approval', methods=['PUT'])
@jwt_required()
@role_required('admin')
def update_captain_approval(user_id):
    captain = User.query.filter_by(id=user_id, role='livreur').first()
    if not captain:
        return jsonify({'message': 'Capitaine introuvable'}), 404

    status = (request.get_json(silent=True) or {}).get('status')
    if status not in ('approved', 'rejected'):
        return jsonify({'message': 'Statut de validation invalide'}), 400

    captain.approval_status = status
    db.session.commit()
    return jsonify({'user': captain.to_dict(), 'message': 'Validation mise à jour'}), 200


# ── Payment Methods ───────────────────────────────────────────────────────────

@admin_bp.route('/payment-methods', methods=['GET'])
@jwt_required()
@role_required('admin')
def list_payment_methods():
    methods = PaymentMethod.query.order_by(PaymentMethod.created_at.desc()).all()
    return jsonify({'payment_methods': [m.to_dict() for m in methods]}), 200


@admin_bp.route('/payment-methods', methods=['POST'])
@jwt_required()
@role_required('admin')
def create_payment_method():
    name = request.form.get('name', '').strip()
    phone_number = request.form.get('phone_number', '').strip()

    if not name or not phone_number:
        return jsonify({'message': 'Nom et numéro de paiement sont requis'}), 400

    logo_url = None
    if 'logo' in request.files and request.files['logo'].filename:
        try:
            logo_url = _save_upload(request.files['logo'], 'payment_methods')
        except ValueError as e:
            return jsonify({'message': str(e)}), 400

    method = PaymentMethod(name=name, phone_number=phone_number, logo=logo_url)
    db.session.add(method)
    db.session.commit()
    return jsonify({'payment_method': method.to_dict(), 'message': 'Moyen de paiement créé'}), 201


@admin_bp.route('/payment-methods/<int:method_id>', methods=['PUT'])
@jwt_required()
@role_required('admin')
def update_payment_method(method_id):
    method = PaymentMethod.query.get(method_id)
    if not method:
        return jsonify({'message': 'Moyen de paiement introuvable'}), 404

    name = request.form.get('name', '').strip()
    phone_number = request.form.get('phone_number', '').strip()
    is_active_raw = request.form.get('is_active')

    if name:
        method.name = name
    if phone_number:
        method.phone_number = phone_number
    if is_active_raw is not None:
        method.is_active = is_active_raw.lower() in ('true', '1', 'yes')

    if 'logo' in request.files and request.files['logo'].filename:
        try:
            method.logo = _save_upload(request.files['logo'], 'payment_methods')
        except ValueError as e:
            return jsonify({'message': str(e)}), 400

    db.session.commit()
    return jsonify({'payment_method': method.to_dict(), 'message': 'Mis à jour'}), 200


@admin_bp.route('/payment-methods/<int:method_id>', methods=['DELETE'])
@jwt_required()
@role_required('admin')
def delete_payment_method(method_id):
    method = PaymentMethod.query.get(method_id)
    if not method:
        return jsonify({'message': 'Moyen de paiement introuvable'}), 404
    db.session.delete(method)
    db.session.commit()
    return jsonify({'message': 'Supprimé'}), 200


# ── Recharge Requests ─────────────────────────────────────────────────────────

@admin_bp.route('/recharge-requests', methods=['GET'])
@jwt_required()
@role_required('admin')
def list_recharge_requests():
    status = request.args.get('status')
    query = RechargeRequest.query
    if status:
        query = query.filter_by(status=status)
    requests_ = query.order_by(RechargeRequest.created_at.desc()).all()
    return jsonify({'requests': [r.to_dict() for r in requests_]}), 200


@admin_bp.route('/recharge-requests/<int:req_id>/approve', methods=['PUT'])
@jwt_required()
@role_required('admin')
def approve_recharge(req_id):
    req = RechargeRequest.query.get(req_id)
    if not req:
        return jsonify({'message': 'Demande introuvable'}), 404
    if req.status != 'en_attente':
        return jsonify({'message': 'Demande déjà traitée'}), 400

    req.status = 'verifie'
    req.captain.balance += req.amount
    db.session.commit()
    return jsonify({'request': req.to_dict(), 'message': 'Demande approuvée, solde mis à jour'}), 200


@admin_bp.route('/recharge-requests/<int:req_id>/reject', methods=['PUT'])
@jwt_required()
@role_required('admin')
def reject_recharge(req_id):
    req = RechargeRequest.query.get(req_id)
    if not req:
        return jsonify({'message': 'Demande introuvable'}), 404
    if req.status != 'en_attente':
        return jsonify({'message': 'Demande déjà traitée'}), 400

    data = request.get_json(silent=True) or {}
    reason = (data.get('reason') or '').strip()

    req.status = 'refuse'
    req.rejection_reason = reason or None
    db.session.commit()
    return jsonify({'request': req.to_dict(), 'message': 'Demande refusée'}), 200
