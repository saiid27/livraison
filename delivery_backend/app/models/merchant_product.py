from app import db
from datetime import datetime


class MerchantProduct(db.Model):
    __tablename__ = 'merchant_products'

    id = db.Column(db.Integer, primary_key=True)
    merchant_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    name = db.Column(db.String(120), nullable=False)
    price = db.Column(db.Float, nullable=False)
    quantity = db.Column(db.Integer, nullable=False, default=0)
    image = db.Column(db.String(255), nullable=True)
    is_active = db.Column(db.Boolean, nullable=False, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    merchant = db.relationship('User', backref='products', lazy=True)

    def to_dict(self):
        return {
            'id': self.id,
            'merchant_id': self.merchant_id,
            'merchant_name': self.merchant.name if self.merchant else None,
            'merchant_contact_phone': self.merchant.merchant_contact_phone if self.merchant else None,
            'merchant_payment_phone': self.merchant.merchant_payment_phone if self.merchant else None,
            'name': self.name,
            'price': self.price,
            'quantity': self.quantity,
            'image': self.image,
            'is_active': self.is_active,
            'created_at': self.created_at.isoformat(),
            'updated_at': self.updated_at.isoformat() if self.updated_at else None,
        }
