from app import db
from datetime import datetime


class PaymentMethod(db.Model):
    __tablename__ = 'payment_methods'

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    phone_number = db.Column(db.String(20), nullable=False)
    logo = db.Column(db.String(255), nullable=True)
    logo_data = db.Column(db.LargeBinary, nullable=True)
    logo_mime = db.Column(db.String(60), nullable=True)
    is_active = db.Column(db.Boolean, default=True, nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'phone_number': self.phone_number,
            'logo': (
                f'/api/media/payment-methods/{self.id}/logo'
                if self.logo_data else self.logo
            ),
            'is_active': self.is_active,
            'created_at': self.created_at.isoformat(),
        }
