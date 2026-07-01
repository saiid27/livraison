from app import db
from datetime import datetime


class User(db.Model):
    __tablename__ = 'users'

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(150), unique=True, nullable=False)
    phone = db.Column(db.String(20), nullable=False)
    password_hash = db.Column(db.String(256), nullable=False)
    role = db.Column(
        db.Enum('client', 'livreur', 'car_captain', 'merchant', 'admin', name='user_role'),
        nullable=False,
        default='client',
    )
    avatar = db.Column(db.String(255), nullable=True)
    id_card_image = db.Column(db.String(255), nullable=True)
    vehicle_image = db.Column(db.String(255), nullable=True)
    vehicle_registration_image = db.Column(db.String(255), nullable=True)
    permit_image = db.Column(db.String(255), nullable=True)
    approval_status = db.Column(db.String(20), nullable=False, default='approved')
    reset_code = db.Column(db.String(6), nullable=True)
    reset_code_expires_at = db.Column(db.DateTime, nullable=True)
    otp_requested_at = db.Column(db.DateTime, nullable=True)
    is_active = db.Column(db.Boolean, default=True)
    balance = db.Column(db.Float, nullable=False, default=0.0)
    vehicle_type = db.Column(db.String(10), nullable=False, default='moto')
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    # Relations
    client_orders = db.relationship('Order', foreign_keys='Order.client_id', backref='client', lazy=True)
    livreur_orders = db.relationship('Order', foreign_keys='Order.livreur_id', backref='livreur', lazy=True)

    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'email': self.email,
            'phone': self.phone,
            'role': self.role,
            'avatar': self.avatar,
            'id_card_image': self.id_card_image,
            'vehicle_image': self.vehicle_image,
            'vehicle_registration_image': self.vehicle_registration_image,
            'permit_image': self.permit_image,
            'approval_status': self.approval_status,
            'is_active': self.is_active,
            'balance': self.balance,
            'vehicle_type': self.vehicle_type,
            'created_at': self.created_at.isoformat(),
        }
