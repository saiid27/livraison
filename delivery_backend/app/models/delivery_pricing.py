from app import db
from datetime import datetime


class DeliveryLocation(db.Model):
    __tablename__ = 'delivery_locations'

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(255), unique=True, nullable=False)
    is_active = db.Column(db.Boolean, nullable=False, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'is_active': self.is_active,
            'created_at': self.created_at.isoformat(),
        }


class DeliveryPrice(db.Model):
    __tablename__ = 'delivery_prices'

    id = db.Column(db.Integer, primary_key=True)
    pickup_location_id = db.Column(
        db.Integer,
        db.ForeignKey('delivery_locations.id'),
        nullable=False,
    )
    delivery_location_id = db.Column(
        db.Integer,
        db.ForeignKey('delivery_locations.id'),
        nullable=False,
    )
    price = db.Column(db.Float, nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(
        db.DateTime,
        default=datetime.utcnow,
        onupdate=datetime.utcnow,
    )

    pickup_location = db.relationship(
        'DeliveryLocation',
        foreign_keys=[pickup_location_id],
        lazy=True,
    )
    delivery_location = db.relationship(
        'DeliveryLocation',
        foreign_keys=[delivery_location_id],
        lazy=True,
    )

    __table_args__ = (
        db.UniqueConstraint(
            'pickup_location_id',
            'delivery_location_id',
            name='uq_delivery_price_pair',
        ),
    )

    def to_dict(self):
        return {
            'id': self.id,
            'pickup_location_id': self.pickup_location_id,
            'delivery_location_id': self.delivery_location_id,
            'pickup': self.pickup_location.name if self.pickup_location else None,
            'delivery': self.delivery_location.name if self.delivery_location else None,
            'price': self.price,
            'created_at': self.created_at.isoformat(),
            'updated_at': self.updated_at.isoformat() if self.updated_at else None,
        }
