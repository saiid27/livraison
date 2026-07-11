from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app import db
from app.image_storage import read_image_upload
from app.models.order import Order
from app.models.user import User
from app.models.merchant_product import MerchantProduct
from app.models.merchant_order import MerchantOrder
from app.utils.decorators import role_required
from app.delivery_locations import (
    all_delivery_locations,
    is_delivery_location,
    trial_delivery_price,
)
from app.broadcast import compute_broadcast_state

client_bp = Blueprint('client', __name__)


@client_bp.route('/delivery-locations', methods=['GET'])
def delivery_locations():
    return jsonify({'locations': all_delivery_locations()}), 200


@client_bp.route('/delivery-price', methods=['GET'])
def delivery_price():
    pickup = str(request.args.get('pickup') or '').strip()
    delivery = str(request.args.get('delivery') or '').strip()
    return jsonify({'price': trial_delivery_price(pickup, delivery)}), 200


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
    if (not is_delivery_location(pickup_address) or
            not is_delivery_location(delivery_address)):
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
    data = order.to_dict()
    if order.status == 'en_attente':
        data['broadcast'] = compute_broadcast_state(order)
    else:
        data['broadcast'] = None
    return jsonify({'order': data}), 200


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


@client_bp.route('/products', methods=['GET'])
def list_products():
    merchant_id = request.args.get('merchant_id')
    products = MerchantProduct.query.filter(
        MerchantProduct.is_active == True,
        MerchantProduct.quantity > 0,
    )
    if merchant_id:
        products = products.filter(MerchantProduct.merchant_id == merchant_id)
    products = products.order_by(MerchantProduct.created_at.desc()).all()
    return jsonify({'products': [product.to_dict() for product in products]}), 200


@client_bp.route('/merchants', methods=['GET'])
def list_merchants():
    merchants = (
        User.query.join(MerchantProduct, User.id == MerchantProduct.merchant_id)
        .filter(
            User.role == 'merchant',
            User.is_active == True,
            MerchantProduct.is_active == True,
            MerchantProduct.quantity > 0,
        )
        .distinct()
        .order_by(User.name.asc())
        .all()
    )

    payload = []
    for merchant in merchants:
        merchant_data = merchant.to_dict()
        available_products = [
            product
            for product in merchant.products
            if product.is_active and product.quantity > 0
        ]
        payload.append({
            'id': merchant.id,
            'name': merchant.name,
            'avatar': merchant_data['avatar'],
            'merchant_contact_phone': merchant.merchant_contact_phone,
            'merchant_payment_phone': merchant.merchant_payment_phone,
            'merchant_payment_methods': [
                method.to_dict()
                for method in merchant.merchant_payment_methods
                if method.is_active
            ],
            'product_count': len(available_products),
        })

    return jsonify({'merchants': payload}), 200


@client_bp.route('/product-orders', methods=['GET'])
@jwt_required()
@role_required('client')
def list_product_orders():
    user_id = get_jwt_identity()
    orders = MerchantOrder.query.filter_by(
        client_id=user_id,
    ).order_by(MerchantOrder.created_at.desc()).all()
    return jsonify({'orders': [order.to_dict() for order in orders]}), 200


@client_bp.route('/product-orders', methods=['POST'])
@jwt_required()
@role_required('client')
def create_product_order():
    user_id = get_jwt_identity()
    data = request.form.to_dict() if request.form else (request.get_json(silent=True) or {})
    product_id = data.get('product_id')
    quantity_raw = data.get('quantity', 1)
    payment_phone_from = str(data.get('payment_phone_from', '')).strip()
    buyer_name = str(data.get('buyer_name', '')).strip()
    notes = str(data.get('notes', '')).strip() or None

    try:
        quantity = int(quantity_raw)
    except (TypeError, ValueError):
        quantity = 0

    if not product_id or quantity <= 0 or not payment_phone_from or not buyer_name:
        return jsonify({'message': 'Produit, quantité, nom et numéro de paiement requis'}), 400
    if 'payment_screenshot' not in request.files or not request.files['payment_screenshot'].filename:
        return jsonify({'message': 'صورة الدفع مطلوبة'}), 400

    product = MerchantProduct.query.filter_by(
        id=product_id,
        is_active=True,
    ).first()
    if not product:
        return jsonify({'message': 'Produit introuvable'}), 404
    if product.quantity < quantity:
        return jsonify({'message': 'Quantité insuffisante'}), 400

    try:
        payment_screenshot_data, payment_screenshot_mime = read_image_upload(
            request.files['payment_screenshot']
        )
    except ValueError as error:
        return jsonify({'message': str(error)}), 400

    product.quantity -= quantity
    order = MerchantOrder(
        merchant_id=product.merchant_id,
        client_id=user_id,
        product_id=product.id,
        product_name=product.name,
        product_image=product.image,
        product_image_data=product.image_data,
        product_image_mime=product.image_mime,
        unit_price=product.price,
        quantity=quantity,
        total_price=product.price * quantity,
        payment_phone_from=payment_phone_from,
        payment_screenshot_data=payment_screenshot_data,
        payment_screenshot_mime=payment_screenshot_mime,
        buyer_name=buyer_name,
        notes=notes,
    )
    db.session.add(order)
    db.session.commit()
    return jsonify({'order': order.to_dict(), 'message': 'Commande envoyée'}), 201
