from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app import db
from app.models.order import Order
from app.models.user import User
from app.utils.decorators import role_required
from app.delivery_locations import DELIVERY_LOCATIONS, trial_delivery_price

client_bp = Blueprint('client', __name__)


@client_bp.route('/orders', methods=['GET'])
@jwt_required()
@role_required('client')
def get_orders():
    user_id = get_jwt_identity()
    orders = Order.query.filter_by(client_id=user_id).order_by(Order.created_at.desc()).all()
    return jsonify({'orders': [o.to_dict() for o in orders]}), 200


@client_bp.route('/orders', methods=['POST'])
@jwt_required()
@role_required('client')
def create_order():
    user_id = get_jwt_identity()
    data = request.get_json()

    required = ['description', 'pickup_address', 'delivery_address']
    if not all(k in data for k in required):
        return jsonify({'message': 'Champs manquants'}), 400

    pickup_address = data['pickup_address'].strip()
    delivery_address = data['delivery_address'].strip()
    if (pickup_address not in DELIVERY_LOCATIONS or
            delivery_address not in DELIVERY_LOCATIONS):
        return jsonify({'message': 'Veuillez choisir un lieu disponible'}), 400
    if pickup_address == delivery_address:
        return jsonify({'message': 'Les deux points doivent être différents'}), 400

    service_type = data.get('service_type', 'delivery')
    if service_type not in {'delivery', 'course'}:
        return jsonify({'message': 'Type de service invalide'}), 400

    order = Order(
        client_id=user_id,
        description=data['description'],
        pickup_address=pickup_address,
        delivery_address=delivery_address,
        service_type=service_type,
        price=trial_delivery_price(pickup_address, delivery_address),
        notes=data.get('notes'),
    )
    db.session.add(order)
    db.session.commit()

    return jsonify({'order': order.to_dict()}), 201


@client_bp.route('/orders/<int:order_id>', methods=['GET'])
@jwt_required()
@role_required('client')
def get_order(order_id):
    user_id = get_jwt_identity()
    order = Order.query.filter_by(id=order_id, client_id=user_id).first()
    if not order:
        return jsonify({'message': 'Commande introuvable'}), 404
    return jsonify({'order': order.to_dict()}), 200


@client_bp.route('/orders/<int:order_id>/cancel', methods=['PUT'])
@jwt_required()
@role_required('client')
def cancel_order(order_id):
    user_id = get_jwt_identity()
    order = Order.query.filter_by(id=order_id, client_id=user_id).first()

    if not order:
        return jsonify({'message': 'Commande introuvable'}), 404
    if order.status != 'en_attente':
        return jsonify({'message': 'Impossible d\'annuler une commande en cours ou livrée'}), 400

    order.status = 'annule'
    db.session.commit()
    return jsonify({'order': order.to_dict(), 'message': 'Commande annulée'}), 200
