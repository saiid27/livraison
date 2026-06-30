from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required
from app import db
from app.models.order import Order
from app.models.user import User
from app.utils.decorators import role_required

admin_bp = Blueprint('admin', __name__)


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
    }
    return jsonify({'stats': stats}), 200


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
