from app import db
from datetime import datetime


class CashTransaction(db.Model):
    __tablename__ = 'cash_transactions'

    id = db.Column(db.Integer, primary_key=True)
    transaction_type = db.Column(db.String(20), nullable=False)
    amount = db.Column(db.Float, nullable=False)
    description = db.Column(db.Text, nullable=True)
    recharge_request_id = db.Column(
        db.Integer,
        db.ForeignKey('recharge_requests.id'),
        nullable=True,
        unique=True,
    )
    order_id = db.Column(
        db.Integer,
        db.ForeignKey('orders.id'),
        nullable=True,
    )
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    recharge_request = db.relationship(
        'RechargeRequest',
        backref='cash_transaction',
        lazy=True,
    )
    order = db.relationship(
        'Order',
        backref='commission_cash_transaction',
        lazy=True,
    )

    def to_dict(self):
        recharge = self.recharge_request
        order = self.order
        captain = recharge.captain if recharge and recharge.captain else None
        if not captain and order and order.livreur:
            captain = order.livreur
        return {
            'id': self.id,
            'type': self.transaction_type,
            'amount': self.amount,
            'description': self.description,
            'recharge_request_id': self.recharge_request_id,
            'order_id': self.order_id,
            'captain_name': captain.name if captain else None,
            'created_at': self.created_at.isoformat(),
        }
