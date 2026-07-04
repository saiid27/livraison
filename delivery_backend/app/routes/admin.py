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
from app.models.account_deletion_request import AccountDeletionRequest
from app.models.merchant_product import MerchantProduct
from app.models.merchant_order import MerchantOrder
from app.models.merchant_payment_method import MerchantPaymentMethod
from app.models.cash_transaction import CashTransaction
from app.utils.decorators import role_required
from datetime import datetime

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


def _cashbox_totals():
    recharges = db.session.query(
        db.func.coalesce(
            db.func.sum(CashTransaction.amount),
            0,
        )
    ).filter_by(transaction_type='recharge').scalar()
    expenses = db.session.query(
        db.func.coalesce(
            db.func.sum(CashTransaction.amount),
            0,
        )
    ).filter_by(transaction_type='expense').scalar()
    return float(recharges or 0), float(expenses or 0)


def _ensure_recharge_cash_transactions():
    verified_requests = RechargeRequest.query.filter_by(status='verifie').all()
    for req in verified_requests:
        exists = CashTransaction.query.filter_by(
            recharge_request_id=req.id,
            transaction_type='recharge',
        ).first()
        if not exists:
            db.session.add(
                CashTransaction(
                    transaction_type='recharge',
                    amount=req.amount,
                    description=f'Recharge vérifiée #{req.id}',
                    recharge_request_id=req.id,
                    created_at=req.updated_at or req.created_at,
                )
            )


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
        'total_livreurs': User.query.filter(User.role.in_(('livreur', 'car_captain'))).count(),
        'pending_captains': User.query.filter(User.role.in_(('livreur', 'car_captain')), User.approval_status == 'pending').count(),
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
    captains = User.query.filter(
        User.role.in_(('livreur', 'car_captain')),
        User.approval_status == 'pending',
    ).order_by(User.created_at.asc()).all()
    return jsonify({'users': [user.to_dict() for user in captains]}), 200


@admin_bp.route('/captains/<int:user_id>/approval', methods=['PUT'])
@jwt_required()
@role_required('admin')
def update_captain_approval(user_id):
    captain = User.query.filter(
        User.id == user_id,
        User.role.in_(('livreur', 'car_captain')),
    ).first()
    if not captain:
        return jsonify({'message': 'Capitaine introuvable'}), 404

    status = (request.get_json(silent=True) or {}).get('status')
    if status not in ('approved', 'rejected'):
        return jsonify({'message': 'Statut de validation invalide'}), 400
    if status == 'approved':
        required_images = [
            captain.avatar,
            captain.id_card_image,
            captain.vehicle_image,
            captain.vehicle_registration_image,
            captain.permit_image,
        ]
        if any(not image for image in required_images):
            return jsonify({'message': 'لا يمكن قبول الكابتن قبل رفع جميع الصور'}), 400

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
    db.session.add(
        CashTransaction(
            transaction_type='recharge',
            amount=req.amount,
            description=f'Recharge vérifiée #{req.id}',
            recharge_request=req,
        )
    )
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


# ── Cashbox ───────────────────────────────────────────────────────────────────

@admin_bp.route('/cashbox', methods=['GET'])
@jwt_required()
@role_required('admin')
def cashbox_summary():
    _ensure_recharge_cash_transactions()
    db.session.commit()

    total_recharges, total_expenses = _cashbox_totals()
    transactions = CashTransaction.query.order_by(
        CashTransaction.created_at.desc(),
        CashTransaction.id.desc(),
    ).all()

    return jsonify({
        'balance': total_recharges - total_expenses,
        'total_recharges': total_recharges,
        'total_expenses': total_expenses,
        'transactions': [transaction.to_dict() for transaction in transactions],
    }), 200


@admin_bp.route('/cashbox/expenses', methods=['POST'])
@jwt_required()
@role_required('admin')
def create_cashbox_expense():
    _ensure_recharge_cash_transactions()

    data = request.get_json(silent=True) or {}
    try:
        amount = float(str(data.get('amount', '')).strip())
    except (TypeError, ValueError):
        amount = 0

    description = str(data.get('description', '')).strip()
    if amount <= 0:
        return jsonify({'message': 'المبلغ غير صحيح'}), 400
    if not description:
        return jsonify({'message': 'وصف المصروف مطلوب'}), 400

    total_recharges, total_expenses = _cashbox_totals()
    balance = total_recharges - total_expenses
    if amount > balance:
        return jsonify({'message': 'المبلغ المصروف أكبر من المال المتوفر في الصندوق'}), 400

    transaction = CashTransaction(
        transaction_type='expense',
        amount=amount,
        description=description,
    )
    db.session.add(transaction)
    db.session.commit()

    total_recharges, total_expenses = _cashbox_totals()
    return jsonify({
        'transaction': transaction.to_dict(),
        'balance': total_recharges - total_expenses,
        'message': 'تم تسجيل المصروف',
    }), 201


# ── Account Deletion Requests ────────────────────────────────────────────────

@admin_bp.route('/account-deletion-requests', methods=['GET'])
@jwt_required()
@role_required('admin')
def list_account_deletion_requests():
    status = request.args.get('status')
    query = AccountDeletionRequest.query
    if status:
        query = query.filter_by(status=status)
    requests_ = query.order_by(AccountDeletionRequest.created_at.desc()).all()
    return jsonify({'requests': [r.to_dict() for r in requests_]}), 200


@admin_bp.route('/account-deletion-requests/<int:req_id>/approve', methods=['PUT'])
@jwt_required()
@role_required('admin')
def approve_account_deletion(req_id):
    deletion_request = AccountDeletionRequest.query.get(req_id)
    if not deletion_request:
        return jsonify({'message': 'Demande introuvable'}), 404
    if deletion_request.status != 'pending':
        return jsonify({'message': 'Demande déjà traitée'}), 400

    user = User.query.get(deletion_request.user_id)
    if not user:
        user = User.query.filter_by(phone=deletion_request.phone).first()

    if user:
        RechargeRequest.query.filter_by(captain_id=user.id).delete()
        MerchantOrder.query.filter_by(client_id=user.id).delete()
        MerchantOrder.query.filter_by(merchant_id=user.id).delete()
        MerchantPaymentMethod.query.filter_by(merchant_id=user.id).delete()
        MerchantProduct.query.filter_by(merchant_id=user.id).delete()
        Order.query.filter_by(client_id=user.id).delete()
        Order.query.filter_by(livreur_id=user.id).update(
            {'livreur_id': None},
            synchronize_session=False,
        )
        db.session.delete(user)

    deletion_request.status = 'approved'
    deletion_request.processed_at = datetime.utcnow()
    deletion_request.user_id = None
    db.session.commit()
    return jsonify({
        'request': deletion_request.to_dict(),
        'message': 'Compte supprimé',
    }), 200


@admin_bp.route('/account-deletion-requests/<int:req_id>/reject', methods=['PUT'])
@jwt_required()
@role_required('admin')
def reject_account_deletion(req_id):
    deletion_request = AccountDeletionRequest.query.get(req_id)
    if not deletion_request:
        return jsonify({'message': 'Demande introuvable'}), 404
    if deletion_request.status != 'pending':
        return jsonify({'message': 'Demande déjà traitée'}), 400

    data = request.get_json(silent=True) or {}
    deletion_request.status = 'rejected'
    deletion_request.rejection_reason = str(data.get('reason', '')).strip() or None
    deletion_request.processed_at = datetime.utcnow()
    db.session.commit()
    return jsonify({
        'request': deletion_request.to_dict(),
        'message': 'Demande refusée',
    }), 200
