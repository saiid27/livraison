from app import db
from datetime import datetime
from app.media_security import media_url


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
    avatar_data = db.Column(db.LargeBinary, nullable=True)
    avatar_mime = db.Column(db.String(60), nullable=True)
    id_card_image_data = db.Column(db.LargeBinary, nullable=True)
    id_card_image_mime = db.Column(db.String(60), nullable=True)
    vehicle_image_data = db.Column(db.LargeBinary, nullable=True)
    vehicle_image_mime = db.Column(db.String(60), nullable=True)
    vehicle_registration_image_data = db.Column(db.LargeBinary, nullable=True)
    vehicle_registration_image_mime = db.Column(db.String(60), nullable=True)
    permit_image_data = db.Column(db.LargeBinary, nullable=True)
    permit_image_mime = db.Column(db.String(60), nullable=True)
    approval_status = db.Column(db.String(20), nullable=False, default='approved')
    reset_code = db.Column(db.String(6), nullable=True)
    reset_code_expires_at = db.Column(db.DateTime, nullable=True)
    otp_requested_at = db.Column(db.DateTime, nullable=True)
    otp_verified_at = db.Column(db.DateTime, nullable=True)
    is_active = db.Column(db.Boolean, default=True)
    is_developer = db.Column(db.Boolean, nullable=False, default=False)
    balance = db.Column(db.Float, nullable=False, default=0.0)
    vehicle_type = db.Column(db.String(10), nullable=False, default='moto')
    merchant_contact_phone = db.Column(db.String(20), nullable=True)
    merchant_payment_phone = db.Column(db.String(20), nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    # Relations
    client_orders = db.relationship('Order', foreign_keys='Order.client_id', backref='client', lazy=True)
    livreur_orders = db.relationship('Order', foreign_keys='Order.livreur_id', backref='livreur', lazy=True)

    def _image_value(self, field, fallback, data):
        if data:
            if field != 'avatar':
                return media_url('users', self.id, field)
            return f'/api/auth/images/{self.id}/{field}'
        return fallback

    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'email': self.email,
            'phone': self.phone,
            'role': self.role,
            'avatar': self._image_value('avatar', self.avatar, self.avatar_data),
            'id_card_image': self._image_value('id_card_image', self.id_card_image, self.id_card_image_data),
            'vehicle_image': self._image_value('vehicle_image', self.vehicle_image, self.vehicle_image_data),
            'vehicle_registration_image': self._image_value('vehicle_registration_image', self.vehicle_registration_image, self.vehicle_registration_image_data),
            'permit_image': self._image_value('permit_image', self.permit_image, self.permit_image_data),
            'approval_status': self.approval_status,
            'is_active': self.is_active,
            'is_developer': self.is_developer,
            'balance': self.balance,
            'vehicle_type': self.vehicle_type,
            'merchant_contact_phone': self.merchant_contact_phone,
            'merchant_payment_phone': self.merchant_payment_phone,
            'created_at': self.created_at.isoformat(),
        }
