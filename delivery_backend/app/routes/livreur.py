from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from datetime import datetime
from app import db
from app.models.order import Order
from app.models.user import User
from app.utils.decorators import approved_captain_required
from app.broadcast import compute_broadcast_state, is_in_broadcast_window

livreur_bp = Blueprint('livreur', __name__)

COMMISSION_RATE = 0.09


@livreur_bp.route('/available-orders', methods=['GET'])
@jwt_required()
@approved_captain_required
def available_orders():
    candidates = Order.query.filter_by(
        status='en_attente', livreur_id=None
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

    if not is_in_broadcast_window(order):
        return jsonify({'message': 'La diffusion de cette commande est terminée'}), 400

    commission = (order.price or 0.0) * COMMISSION_RATE
    if captain.balance < commission:
        return jsonify({
            'message': 'Solde insuffisant pour accepter cette commande',
            'code': 'insufficient_balance',
            'required': commission,
            'balance': captain.balance,
        }), 400

    captain.balance -= commission
    order.livreur_id = user_id
    order.status = 'en_cours'
    db.session.commit()

    return jsonify({'order': order.to_dict(), 'message': 'Commande acceptée'}), 200


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

    data = request.get_json()
    reason = (data.get('reason') or '').strip()
    if not reason:
        return jsonify({'message': 'Le motif d\'annulation est obligatoire'}), 400

    order.status = 'annule'
    order.cancellation_reason = reason
    db.session.commit()
    return jsonify({'order': order.to_dict(), 'message': 'Commande annulée'}), 200


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
