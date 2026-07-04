from flask import Blueprint, request, jsonify, current_app
from flask_jwt_extended import get_jwt_identity, jwt_required
from pathlib import Path
from uuid import uuid4
from werkzeug.utils import secure_filename
import os

from app import bcrypt, db
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
from app.delivery_locations import trial_delivery_price
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
    incomes = db.session.query(
        db.func.coalesce(
            db.func.sum(CashTransaction.amount),
            0,
        )
    ).filter(CashTransaction.transaction_type.in_(('recharge', 'commission'))).scalar()
    expenses = db.session.query(
        db.func.coalesce(
            db.func.sum(CashTransaction.amount),
            0,
        )
    ).filter(CashTransaction.transaction_type.in_(('expense', 'commission_refund'))).scalar()
    return float(incomes or 0), float(expenses or 0)


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


def _current_developer():
    user = User.query.get(get_jwt_identity())
    if not user or user.role != 'admin' or not user.is_developer:
        return None
    return user


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


@admin_bp.route('/orders', methods=['POST'])
@jwt_required()
@role_required('admin')
def create_manual_order():
    admin_id = get_jwt_identity()
    data = request.get_json(silent=True) or {}

    description = str(data.get('description') or '').strip()
    pickup_address = str(data.get('pickup_address') or '').strip()
    delivery_address = str(data.get('delivery_address') or '').strip()
    customer_name = str(data.get('customer_name') or '').strip()
    customer_phone = str(data.get('customer_phone') or '').strip()
    custom_price = data.get('price')

    if not description or not pickup_address or not delivery_address or not customer_phone:
        return jsonify({'message': 'الوصف ونقاط التوصيل ورقم الزبون مطلوبة'}), 400
    if pickup_address == delivery_address:
        return jsonify({'message': 'Les deux points doivent être différents'}), 400
    if custom_price in (None, ''):
        price = trial_delivery_price(pickup_address, delivery_address)
    else:
        try:
            price = float(custom_price)
        except (TypeError, ValueError):
            return jsonify({'message': 'السعر غير صحيح'}), 400
    if price is None or price <= 0:
        return jsonify({'message': 'السعر مطلوب عندما تكون النقطة خاصة'}), 400

    order = Order(
        client_id=admin_id,
        description=description,
        pickup_address=pickup_address,
        delivery_address=delivery_address,
        service_type='delivery',
        price=price,
        manual_customer_name=customer_name or 'زبون بدون حساب',
        manual_customer_phone=customer_phone,
        notes=data.get('notes'),
    )
    db.session.add(order)
    db.session.commit()
    return jsonify({'order': order.to_dict(), 'message': 'تم إرسال الطلب'}), 201


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


@admin_bp.route('/admin-accounts', methods=['GET'])
@jwt_required()
@role_required('admin')
def list_admin_accounts():
    if not _current_developer():
        return jsonify({'message': 'Accès réservé au développeur'}), 403

    admins = User.query.filter_by(role='admin').order_by(
        User.created_at.desc(),
    ).all()
    return jsonify({'users': [admin.to_dict() for admin in admins]}), 200


@admin_bp.route('/admin-accounts', methods=['POST'])
@jwt_required()
@role_required('admin')
def create_admin_account():
    if not _current_developer():
        return jsonify({'message': 'Accès réservé au développeur'}), 403

    data = request.get_json(silent=True) or {}
    name = str(data.get('name') or '').strip()
    phone = str(data.get('phone') or '').strip()
    password = str(data.get('password') or '').strip()
    email = str(data.get('email') or '').strip().lower()
    is_developer = bool(data.get('is_developer') or False)

    if not name or not phone or not password:
        return jsonify({'message': 'الاسم ورقم الهاتف وكلمة المرور مطلوبة'}), 400
    if len(password) < 6:
        return jsonify({'message': 'كلمة المرور يجب أن تكون 6 أحرف على الأقل'}), 400
    if User.query.filter_by(phone=phone).first():
        return jsonify({'message': 'رقم الهاتف مستخدم بالفعل'}), 409

    if not email:
        email = f'admin.{phone}@mayahsar.local'
    if User.query.filter(db.func.lower(User.email) == email).first():
        return jsonify({'message': 'البريد الإلكتروني مستخدم بالفعل'}), 409

    admin = User(
        name=name,
        email=email,
        phone=phone,
        password_hash=bcrypt.generate_password_hash(password).decode('utf-8'),
        role='admin',
        approval_status='approved',
        is_developer=is_developer,
    )
    db.session.add(admin)
    db.session.commit()
    return jsonify({'user': admin.to_dict(), 'message': 'تم إنشاء حساب الأدمن'}), 201


@admin_bp.route('/admin-accounts/<int:user_id>', methods=['PUT'])
@jwt_required()
@role_required('admin')
def update_admin_account(user_id):
    if not _current_developer():
        return jsonify({'message': 'Accès réservé au développeur'}), 403

    admin = User.query.filter_by(id=user_id, role='admin').first()
    if not admin:
        return jsonify({'message': 'حساب الأدمن غير موجود'}), 404

    data = request.get_json(silent=True) or {}
    if 'is_developer' not in data:
        return jsonify({'message': 'لا توجد صلاحية لتعديلها'}), 400

    is_developer = bool(data.get('is_developer'))
    if admin.is_developer and not is_developer:
        developers_count = User.query.filter_by(
            role='admin',
            is_developer=True,
        ).count()
        if developers_count <= 1:
            return jsonify({'message': 'لا يمكن إزالة آخر حساب ديفلوبر'}), 400

    admin.is_developer = is_developer
    db.session.commit()
    return jsonify({'user': admin.to_dict(), 'message': 'تم تحديث الصلاحية'}), 200


@admin_bp.route('/admin-accounts/<int:user_id>', methods=['DELETE'])
@jwt_required()
@role_required('admin')
def delete_admin_account(user_id):
    current_developer = _current_developer()
    if not current_developer:
        return jsonify({'message': 'Accès réservé au développeur'}), 403

    admin = User.query.filter_by(id=user_id, role='admin').first()
    if not admin:
        return jsonify({'message': 'حساب الأدمن غير موجود'}), 404
    if admin.id == current_developer.id:
        return jsonify({'message': 'لا يمكنك حذف حسابك الحالي'}), 400
    if admin.is_developer:
        developers_count = User.query.filter_by(
            role='admin',
            is_developer=True,
        ).count()
        if developers_count <= 1:
            return jsonify({'message': 'لا يمكن حذف آخر حساب ديفلوبر'}), 400

    db.session.delete(admin)
    db.session.commit()
    return jsonify({'message': 'تم حذف الحساب'}), 200


@admin_bp.route('/captains', methods=['GET'])
@jwt_required()
@role_required('admin')
def list_captains():
    captains = User.query.filter(
        User.role.in_(('livreur', 'car_captain')),
    ).order_by(User.created_at.desc()).all()
    return jsonify({'users': [captain.to_dict() for captain in captains]}), 200


@admin_bp.route('/captains/<int:user_id>', methods=['GET'])
@jwt_required()
@role_required('admin')
def captain_profile(user_id):
    captain = User.query.filter(
        User.id == user_id,
        User.role.in_(('livreur', 'car_captain')),
    ).first()
    if not captain:
        return jsonify({'message': 'Capitaine introuvable'}), 404

    orders = Order.query.filter_by(livreur_id=user_id).order_by(
        Order.created_at.desc(),
    ).all()
    recharges = RechargeRequest.query.filter_by(captain_id=user_id).order_by(
        RechargeRequest.created_at.desc(),
    ).all()
    delivered = sum(1 for order in orders if order.status == 'livre')

    return jsonify({
        'user': captain.to_dict(),
        'orders': [order.to_dict() for order in orders],
        'recharge_requests': [recharge.to_dict() for recharge in recharges],
        'stats': {
            'orders_count': len(orders),
            'delivered_count': delivered,
            'balance': captain.balance,
        },
    }), 200


@admin_bp.route('/merchants', methods=['GET'])
@jwt_required()
@role_required('admin')
def list_merchants():
    merchants = User.query.filter_by(role='merchant').order_by(
        User.created_at.desc(),
    ).all()
    return jsonify({'users': [merchant.to_dict() for merchant in merchants]}), 200


@admin_bp.route('/merchants/<int:user_id>', methods=['GET'])
@jwt_required()
@role_required('admin')
def merchant_profile(user_id):
    merchant = User.query.filter_by(id=user_id, role='merchant').first()
    if not merchant:
        return jsonify({'message': 'Commerçant introuvable'}), 404

    products = MerchantProduct.query.filter_by(merchant_id=user_id).order_by(
        MerchantProduct.created_at.desc(),
    ).all()
    orders = MerchantOrder.query.filter_by(merchant_id=user_id).order_by(
        MerchantOrder.created_at.desc(),
    ).all()
    methods = MerchantPaymentMethod.query.filter_by(merchant_id=user_id).order_by(
        MerchantPaymentMethod.created_at.desc(),
    ).all()

    return jsonify({
        'user': merchant.to_dict(),
        'products': [product.to_dict() for product in products],
        'orders': [order.to_dict() for order in orders],
        'payment_methods': [method.to_dict() for method in methods],
        'stats': {
            'products_count': len(products),
            'orders_count': len(orders),
            'sales_total': sum(order.total_price for order in orders),
        },
    }), 200


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
    if 'logo' not in request.files or not request.files['logo'].filename:
        return jsonify({'message': 'صورة طريقة الدفع إلزامية'}), 400

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
