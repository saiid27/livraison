from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app import db
from app.models.order import Order
from app.utils.decorators import approved_captain_required

livreur_bp = Blueprint('livreur', __name__)


@livreur_bp.route('/available-orders', methods=['GET'])
@jwt_required()
@approved_captain_required
def available_orders():
    orders = Order.query.filter_by(status='en_attente', livreur_id=None).order_by(Order.created_at.desc()).all()
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
    order = Order.query.get(order_id)

    if not order:
        return jsonify({'message': 'Commande introuvable'}), 404
    if order.status != 'en_attente':
        return jsonify({'message': 'Commande déjà prise'}), 400
    if order.livreur_id is not None:
        return jsonify({'message': 'Commande déjà assignée'}), 400

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
