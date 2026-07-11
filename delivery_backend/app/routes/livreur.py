from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from datetime import datetime

from app import db
from app.image_storage import read_image_upload
from app.models.order import Order
from app.models.user import User
from app.models.payment_method import PaymentMethod
from app.models.recharge_request import RechargeRequest
from app.models.cash_transaction import CashTransaction
from app.utils.decorators import approved_captain_required
from app.broadcast import compute_broadcast_state, is_in_broadcast_window

livreur_bp = Blueprint('livreur', __name__)

COMMISSION_RATE = 0.09


def _captain_service_type(role):
    return 'course' if role == 'car_captain' else 'delivery'


@livreur_bp.route('/available-orders', methods=['GET'])
@jwt_required()
@approved_captain_required
def available_orders():
    captain = User.query.get(get_jwt_identity())
    candidates = Order.query.filter_by(
        status='en_attente',
        livreur_id=None,
        service_type=_captain_service_type(captain.role),
    ).order_by(Order.created_at.desc()).all()

    orders = [o for o in candidates if is_in_broadcast_window(o)]
    return jsonify({'orders': [o.to_dict() for o in orders]}), 200


@livreur_bp.route('/my-orders', methods=['GET'])
@jwt_required()
@approved_captain_required
def my_orders():
    user_id = get_jwt_identity()
    orders = Order.query.filter_by(livreur_id=user_id).order_by(Order.created_at.desc()).all()
    return jsonify({'orders': [o.to_dict() for o in orders]}), 200


@livreur_bp.route('/orders/<int:order_id>/accept', methods=['POST'])
@jwt_required()
@approved_captain_required
def accept_order(order_id):
    user_id = get_jwt_identity()
    captain = User.query.get(user_id)
    order = Order.query.get(order_id)

    if not order:
        return jsonify({'message': 'Commande introuvable'}), 404
    if order.status != 'en_attente':
        return jsonify({'message': 'Commande déjà prise'}), 400
    if order.livreur_id is not None:
        return jsonify({'message': 'Commande déjà assignée'}), 400
    if order.service_type != _captain_service_type(captain.role):
        return jsonify({'message': 'Type de commande non autorisé pour ce capitaine'}), 403

    if not is_in_broadcast_window(order):
        return jsonify({'message': 'La diffusion de cette commande est terminée'}), 400

    commission = (order.price or 0.0) * COMMISSION_RATE
    if commission <= 0:
        return jsonify({'message': 'Prix de commande invalide'}), 400
    if captain.balance < commission:
        return jsonify({
            'message': 'Solde insuffisant pour accepter cette commande',
            'code': 'insufficient_balance',
            'required': commission,
            'balance': captain.balance,
        }), 400

    now = datetime.utcnow()
    captain.balance -= commission
    order.livreur_id = user_id
    order.status = 'en_cours'
    order.commission_charged_at = now
    order.commission_amount = commission
    db.session.add(
        CashTransaction(
            transaction_type='commission',
            amount=commission,
            description=f'Commission 9% commande #{order.id}',
            order=order,
            created_at=now,
        )
    )
    db.session.commit()

    return jsonify({'order': order.to_dict(), 'message': 'Commande acceptée'}), 200


@livreur_bp.route('/orders/<int:order_id>/pickup', methods=['POST'])
@jwt_required()
@approved_captain_required
def confirm_pickup(order_id):
    user_id = get_jwt_identity()
    order = Order.query.filter_by(id=order_id, livreur_id=user_id).first()

    if not order:
        return jsonify({'message': 'Commande introuvable'}), 404
    if order.status != 'en_cours':
        return jsonify({'message': 'Cette commande n\'est pas en cours'}), 400
    if order.picked_up_at:
        return jsonify({'order': order.to_dict(), 'message': 'Message déjà récupéré'}), 200

    now = datetime.utcnow()
    order.picked_up_at = now
    db.session.commit()

    return jsonify({
        'order': order.to_dict(),
        'message': 'Message récupéré',
    }), 200


@livreur_bp.route('/orders/<int:order_id>/status', methods=['PUT'])
@jwt_required()
@approved_captain_required
def update_status(order_id):
    user_id = get_jwt_identity()
    order = Order.query.filter_by(id=order_id, livreur_id=user_id).first()

    if not order:
        return jsonify({'message': 'Commande introuvable'}), 404

    data = request.get_json()
    new_status = data.get('status')

    allowed_transitions = {
        'en_cours': ['livre'],
    }

    if new_status not in allowed_transitions.get(order.status, []):
        return jsonify({'message': f'Transition invalide : {order.status} → {new_status}'}), 400
    if new_status == 'livre' and not order.picked_up_at:
        return jsonify({'message': 'Confirmez d\'abord la récupération du message'}), 400

    order.status = new_status
    db.session.commit()
    return jsonify({'order': order.to_dict(), 'message': 'Statut mis à jour'}), 200


@livreur_bp.route('/orders/<int:order_id>/cancel', methods=['POST'])
@jwt_required()
@approved_captain_required
def cancel_order(order_id):
    user_id = get_jwt_identity()
    order = Order.query.filter_by(id=order_id, livreur_id=user_id).first()

    if not order:
        return jsonify({'message': 'Commande introuvable'}), 404
    if order.status != 'en_cours':
        return jsonify({'message': 'Seules les commandes en cours peuvent être annulées'}), 400
    if order.picked_up_at:
        return jsonify({'message': 'Impossible d\'annuler après récupération du message'}), 400

    data = request.get_json()
    reason = (data.get('reason') or '').strip()
    if not reason:
        return jsonify({'message': 'Le motif d\'annulation est obligatoire'}), 400

    order.status = 'annule'
    order.cancellation_reason = reason
    if order.commission_charged_at and order.commission_amount:
        captain = User.query.get(user_id)
        captain.balance += order.commission_amount
        db.session.add(
            CashTransaction(
                transaction_type='commission_refund',
                amount=order.commission_amount,
                description=f'Remboursement commission commande #{order.id}',
                order=order,
            )
        )
        order.commission_charged_at = None
    db.session.commit()
    return jsonify({'order': order.to_dict(), 'message': 'Commande annulée'}), 200


@livreur_bp.route('/payment-methods', methods=['GET'])
@jwt_required()
@approved_captain_required
def list_payment_methods():
    methods = PaymentMethod.query.filter_by(is_active=True).order_by(PaymentMethod.id).all()
    return jsonify({'payment_methods': [m.to_dict() for m in methods]}), 200


@livreur_bp.route('/recharge-requests', methods=['GET'])
@jwt_required()
@approved_captain_required
def list_recharge_requests():
    user_id = get_jwt_identity()
    requests_ = RechargeRequest.query.filter_by(captain_id=user_id).order_by(
        RechargeRequest.created_at.desc()
    ).all()
    return jsonify({'requests': [r.to_dict() for r in requests_]}), 200


@livreur_bp.route('/wallet-transactions', methods=['GET'])
@jwt_required()
@approved_captain_required
def wallet_transactions():
    user_id = get_jwt_identity()
    recharges = RechargeRequest.query.filter_by(captain_id=user_id).all()
    order_transactions = (
        CashTransaction.query.join(Order, CashTransaction.order_id == Order.id)
        .filter(
            Order.livreur_id == user_id,
            CashTransaction.transaction_type.in_(
                ('commission', 'commission_refund')
            ),
        )
        .all()
    )

    transactions = []
    for req in recharges:
        transactions.append({
            'id': f'recharge-{req.id}',
            'type': 'recharge',
            'amount': req.amount,
            'status': req.status,
            'payment_method_name': req.payment_method.name if req.payment_method else None,
            'description': req.rejection_reason,
            'order_id': None,
            'created_at': req.updated_at.isoformat() if req.updated_at else req.created_at.isoformat(),
        })
    for transaction in order_transactions:
        transactions.append({
            'id': f'{transaction.transaction_type}-{transaction.id}',
            'type': transaction.transaction_type,
            'amount': transaction.amount,
            'status': 'verifie',
            'payment_method_name': None,
            'description': transaction.description,
            'order_id': transaction.order_id,
            'created_at': transaction.created_at.isoformat(),
        })

    transactions.sort(key=lambda item: item['created_at'], reverse=True)
    return jsonify({'transactions': transactions}), 200


@livreur_bp.route('/recharge-requests', methods=['POST'])
@jwt_required()
@approved_captain_required
def submit_recharge_request():
    user_id = get_jwt_identity()

    amount_raw = request.form.get('amount', '').strip()
    phone_from = request.form.get('phone_from', '').strip()
    payment_method_id = request.form.get('payment_method_id', '').strip()

    if not amount_raw or not phone_from or not payment_method_id:
        return jsonify({'message': 'Champs manquants'}), 400

    try:
        amount = float(amount_raw)
        if amount <= 0:
            raise ValueError
    except ValueError:
        return jsonify({'message': 'Montant invalide'}), 400
    if amount < 50:
        return jsonify({'message': 'أدنى حد للشحن 50 أوقية'}), 400

    method = PaymentMethod.query.filter_by(id=int(payment_method_id), is_active=True).first()
    if not method:
        return jsonify({'message': 'Moyen de paiement invalide'}), 400

    screenshot_data = None
    screenshot_mime = None
    if 'screenshot' in request.files and request.files['screenshot'].filename:
        try:
            screenshot_data, screenshot_mime = read_image_upload(request.files['screenshot'])
        except ValueError:
            return jsonify({'message': 'Format image non pris en charge'}), 400

    req = RechargeRequest(
        captain_id=user_id,
        payment_method_id=int(payment_method_id),
        amount=amount,
        phone_from=phone_from,
        screenshot_data=screenshot_data,
        screenshot_mime=screenshot_mime,
    )
    db.session.add(req)
    db.session.commit()
    return jsonify({'request': req.to_dict(), 'message': 'Demande soumise'}), 201


@livreur_bp.route('/wallet', methods=['GET'])
@jwt_required()
@approved_captain_required
def wallet():
    user_id = get_jwt_identity()
    captain = User.query.get(user_id)
    completed = Order.query.filter_by(livreur_id=user_id, status='livre').count()
    return jsonify({
        'balance': captain.balance,
        'vehicle_type': captain.vehicle_type,
        'completed_deliveries': completed,
        'commission_rate': COMMISSION_RATE,
    }), 200
