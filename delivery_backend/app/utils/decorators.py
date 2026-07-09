from functools import wraps
from flask import jsonify
from flask_jwt_extended import get_jwt_identity
from app.models.user import User


def role_required(*roles):
    def decorator(fn):
        @wraps(fn)
        def wrapper(*args, **kwargs):
            user_id = get_jwt_identity()
            user = User.query.get(user_id)
            if not user or not user.is_active or user.role not in roles:
                return jsonify({'message': 'Accès refusé'}), 403
            return fn(*args, **kwargs)
        return wrapper
    return decorator


def approved_captain_required(fn):
    @wraps(fn)
    def wrapper(*args, **kwargs):
        user = User.query.get(get_jwt_identity())
        if not user or not user.is_active or user.role not in ('livreur', 'car_captain'):
            return jsonify({'message': 'Accès refusé'}), 403
        if user.approval_status != 'approved':
            return jsonify({'message': 'Compte capitaine en attente de validation'}), 403
        return fn(*args, **kwargs)
    return wrapper
