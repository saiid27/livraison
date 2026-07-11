from app import db
from datetime import datetime
from app.media_security import media_url


class RechargeRequest(db.Model):
    __tablename__ = 'recharge_requests'

    id = db.Column(db.Integer, primary_key=True)
    captain_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    payment_method_id = db.Column(db.Integer, db.ForeignKey('payment_methods.id'), nullable=False)
    amount = db.Column(db.Float, nullable=False)
    phone_from = db.Column(db.String(20), nullable=False)
    screenshot = db.Column(db.String(255), nullable=True)
    screenshot_data = db.Column(db.LargeBinary, nullable=True)
    screenshot_mime = db.Column(db.String(60), nullable=True)
    status = db.Column(db.String(20), nullable=False, default='en_attente')  # en_attente | verifie | refuse
    rejection_reason = db.Column(db.Text, nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    captain = db.relationship('User', backref='recharge_requests', lazy=True)
    payment_method = db.relationship('PaymentMethod', backref='recharge_requests', lazy=True)

    def to_dict(self):
        return {
            'id': self.id,
            'captain_id': self.captain_id,
            'captain_name': self.captain.name if self.captain else None,
            'payment_method_id': self.payment_method_id,
            'payment_method_name': self.payment_method.name if self.payment_method else None,
            'amount': self.amount,
            'phone_from': self.phone_from,
            'screenshot': (
                media_url('recharge-requests', self.id, 'screenshot')
                if self.screenshot_data else self.screenshot
            ),
            'status': self.status,
            'rejection_reason': self.rejection_reason,
            'created_at': self.created_at.isoformat(),
            'updated_at': self.updated_at.isoformat() if self.updated_at else None,
        }
