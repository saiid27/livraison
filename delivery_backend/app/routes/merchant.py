from flask import Blueprint, request, jsonify, current_app
from flask_jwt_extended import jwt_required, get_jwt_identity
from pathlib import Path
from uuid import uuid4
from werkzeug.utils import secure_filename
import os

from app import db
from app.models.user import User
from app.models.merchant_product import MerchantProduct
from app.models.merchant_order import MerchantOrder
from app.models.merchant_payment_method import MerchantPaymentMethod
from app.utils.decorators import role_required

merchant_bp = Blueprint('merchant', __name__)

_ALLOWED_EXTS = {'.jpg', '.jpeg', '.png', '.webp'}
_IMAGE_MIME_BY_EXT = {
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.png': 'image/png',
    '.webp': 'image/webp',
}


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


def _save_product_image(upload):
    return _save_upload(upload, 'products')


def _read_image_upload(upload):
    original = secure_filename(upload.filename or '')
    ext = Path(original).suffix.lower()
    mime_type = _IMAGE_MIME_BY_EXT.get(ext)
    if not mime_type:
        raise ValueError('Format image non pris en charge')
    image_data = upload.read()
    if not image_data:
        raise ValueError('Image vide')
    return image_data, mime_type


def _float_value(value):
    try:
        result = float(str(value).strip())
        return result if result >= 0 else None
    except (TypeError, ValueError):
        return None


def _int_value(value):
    try:
        result = int(str(value).strip())
        return result if result >= 0 else None
    except (TypeError, ValueError):
        return None


@merchant_bp.route('/profile', methods=['GET'])
@jwt_required()
@role_required('merchant')
def get_profile():
    merchant = User.query.get(get_jwt_identity())
    return jsonify({'user': merchant.to_dict()}), 200


@merchant_bp.route('/profile', methods=['PUT'])
@jwt_required()
@role_required('merchant')
def update_profile():
    merchant = User.query.get(get_jwt_identity())
    data = request.form.to_dict() if request.form else (request.get_json(silent=True) or {})
    contact_phone = str(data.get('merchant_contact_phone', '')).strip()
    payment_phone = str(data.get('merchant_payment_phone', '')).strip()
    has_new_avatar = (
        'profile_image' in request.files and request.files['profile_image'].filename
    )

    if not merchant.avatar and not has_new_avatar:
        return jsonify({'message': 'صورة البروفايل إلزامية'}), 400

    merchant.merchant_contact_phone = contact_phone or None
    merchant.merchant_payment_phone = payment_phone or None
    if has_new_avatar:
        try:
            image_data, mime_type = _read_image_upload(request.files['profile_image'])
            merchant.avatar_data = image_data
            merchant.avatar_mime = mime_type
            merchant.avatar = f'/api/auth/images/{merchant.id}/avatar'
        except ValueError as error:
            return jsonify({'message': str(error)}), 400
    db.session.commit()
    return jsonify({'user': merchant.to_dict(), 'message': 'Profil mis à jour'}), 200


@merchant_bp.route('/payment-methods', methods=['GET'])
@jwt_required()
@role_required('merchant')
def list_payment_methods():
    merchant_id = get_jwt_identity()
    methods = MerchantPaymentMethod.query.filter_by(
        merchant_id=merchant_id,
        is_active=True,
    ).order_by(MerchantPaymentMethod.created_at.desc()).all()
    return jsonify({'payment_methods': [method.to_dict() for method in methods]}), 200


@merchant_bp.route('/payment-methods', methods=['POST'])
@jwt_required()
@role_required('merchant')
def create_payment_method():
    merchant_id = get_jwt_identity()
    data = request.get_json(silent=True) or {}
    name = str(data.get('name', '')).strip()
    phone_number = str(data.get('phone_number', '')).strip()

    if not name or not phone_number:
        return jsonify({'message': 'اسم طريقة الدفع ورقمها مطلوبان'}), 400

    method = MerchantPaymentMethod(
        merchant_id=merchant_id,
        name=name,
        phone_number=phone_number,
    )
    db.session.add(method)
    db.session.commit()
    return jsonify({'payment_method': method.to_dict(), 'message': 'تمت إضافة طريقة الدفع'}), 201


@merchant_bp.route('/products', methods=['GET'])
@jwt_required()
@role_required('merchant')
def list_products():
    merchant_id = get_jwt_identity()
    products = MerchantProduct.query.filter_by(
        merchant_id=merchant_id,
        is_active=True,
    ).order_by(MerchantProduct.created_at.desc()).all()
    return jsonify({'products': [product.to_dict() for product in products]}), 200


@merchant_bp.route('/products', methods=['POST'])
@jwt_required()
@role_required('merchant')
def create_product():
    merchant_id = get_jwt_identity()
    name = request.form.get('name', '').strip()
    price = _float_value(request.form.get('price'))
    quantity = _int_value(request.form.get('quantity'))

    if not name or price is None or quantity is None:
        return jsonify({'message': 'Nom, prix et quantité sont requis'}), 400

    if 'image' not in request.files or not request.files['image'].filename:
        return jsonify({'message': 'صورة المنتج إلزامية'}), 400

    try:
        image_url = _save_product_image(request.files['image'])
    except ValueError as error:
        return jsonify({'message': str(error)}), 400

    product = MerchantProduct(
        merchant_id=merchant_id,
        name=name,
        price=price,
        quantity=quantity,
        image=image_url,
    )
    db.session.add(product)
    db.session.commit()
    return jsonify({'product': product.to_dict(), 'message': 'Produit créé'}), 201


@merchant_bp.route('/products/<int:product_id>', methods=['PUT'])
@jwt_required()
@role_required('merchant')
def update_product(product_id):
    merchant_id = get_jwt_identity()
    product = MerchantProduct.query.filter_by(
        id=product_id,
        merchant_id=merchant_id,
        is_active=True,
    ).first()
    if not product:
        return jsonify({'message': 'Produit introuvable'}), 404

    name = request.form.get('name', '').strip()
    price = _float_value(request.form.get('price'))
    quantity = _int_value(request.form.get('quantity'))

    if name:
        product.name = name
    if price is not None:
        product.price = price
    if quantity is not None:
        product.quantity = quantity
    if 'image' in request.files and request.files['image'].filename:
        try:
            product.image = _save_product_image(request.files['image'])
        except ValueError as error:
            return jsonify({'message': str(error)}), 400

    db.session.commit()
    return jsonify({'product': product.to_dict(), 'message': 'Produit mis à jour'}), 200


@merchant_bp.route('/orders', methods=['GET'])
@jwt_required()
@role_required('merchant')
def list_orders():
    merchant_id = get_jwt_identity()
    orders = MerchantOrder.query.filter_by(
        merchant_id=merchant_id,
    ).order_by(MerchantOrder.created_at.desc()).all()
    return jsonify({'orders': [order.to_dict() for order in orders]}), 200


@merchant_bp.route('/orders/<int:order_id>/status', methods=['PUT'])
@jwt_required()
@role_required('merchant')
def update_order_status(order_id):
    merchant_id = get_jwt_identity()
    order = MerchantOrder.query.filter_by(
        id=order_id,
        merchant_id=merchant_id,
    ).first()
    if not order:
        return jsonify({'message': 'Commande introuvable'}), 404

    status = (request.get_json(silent=True) or {}).get('status')
    if status not in ('pending', 'confirmed', 'delivered', 'cancelled'):
        return jsonify({'message': 'Statut invalide'}), 400

    order.status = status
    db.session.commit()
    return jsonify({'order': order.to_dict(), 'message': 'Statut mis à jour'}), 200


@merchant_bp.route('/sales', methods=['GET'])
@jwt_required()
@role_required('merchant')
def sales_history():
    merchant_id = get_jwt_identity()
    orders = MerchantOrder.query.filter(
        MerchantOrder.merchant_id == merchant_id,
        MerchantOrder.status != 'cancelled',
    ).order_by(MerchantOrder.created_at.desc()).all()
    return jsonify({'orders': [order.to_dict() for order in orders]}), 200
