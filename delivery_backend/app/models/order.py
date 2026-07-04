from app import db
from datetime import datetime


class Order(db.Model):
    __tablename__ = 'orders'

    id = db.Column(db.Integer, primary_key=True)
    client_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    livreur_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=True)
    description = db.Column(db.Text, nullable=False)
    pickup_address = db.Column(db.String(255), nullable=False)
    delivery_address = db.Column(db.String(255), nullable=False)
    service_type = db.Column(db.String(20), nullable=False, default='delivery')
    price = db.Column(db.Float, nullable=True)
    manual_customer_name = db.Column(db.String(120), nullable=True)
    manual_customer_phone = db.Column(db.String(20), nullable=True)
    picked_up_at = db.Column(db.DateTime, nullable=True)
    commission_charged_at = db.Column(db.DateTime, nullable=True)
    commission_amount = db.Column(db.Float, nullable=True)
    status = db.Column(
        db.Enum('en_attente', 'en_cours', 'livre', 'annule', name='order_status'),
        nullable=False,
        default='en_attente'
    )
    notes = db.Column(db.Text, nullable=True)
    cancellation_reason = db.Column(db.Text, nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    def to_dict(self, include_users=True):
        data = {
            'id': self.id,
            'client_id': self.client_id,
            'livreur_id': self.livreur_id,
            'description': self.description,
            'pickup_address': self.pickup_address,
            'delivery_address': self.delivery_address,
            'service_type': self.service_type,
            'price': self.price,
            'status': self.status,
            'notes': self.notes,
            'cancellation_reason': self.cancellation_reason,
            'picked_up_at': self.picked_up_at.isoformat() if self.picked_up_at else None,
            'commission_charged_at': self.commission_charged_at.isoformat() if self.commission_charged_at else None,
            'commission_amount': self.commission_amount,
            'created_at': self.created_at.isoformat(),
            'updated_at': self.updated_at.isoformat() if self.updated_at else None,
        }
        if include_users:
            if self.manual_customer_name or self.manual_customer_phone:
                data['client_name'] = self.manual_customer_name
                data['client_phone'] = self.manual_customer_phone
            elif self.client:
                data['client_name'] = self.client.name
                data['client_phone'] = self.client.phone
            else:
                data['client_name'] = None
                data['client_phone'] = None
            if self.livreur:
                data['livreur_name'] = self.livreur.name
                data['livreur_phone'] = self.livreur.phone
            else:
                data['livreur_name'] = None
                data['livreur_phone'] = None
        return data
