from app import db
from datetime import datetime


class MerchantPaymentMethod(db.Model):
    __tablename__ = 'merchant_payment_methods'

    id = db.Column(db.Integer, primary_key=True)
    merchant_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    name = db.Column(db.String(80), nullable=False)
    phone_number = db.Column(db.String(20), nullable=False)
    is_active = db.Column(db.Boolean, nullable=False, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    merchant = db.relationship('User', backref='merchant_payment_methods', lazy=True)

    def to_dict(self):
        return {
            'id': self.id,
            'merchant_id': self.merchant_id,
            'name': self.name,
            'phone_number': self.phone_number,
            'is_active': self.is_active,
            'created_at': self.created_at.isoformat(),
        }
