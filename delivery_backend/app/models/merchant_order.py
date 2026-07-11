from app import db
from datetime import datetime
from app.media_security import media_url


class MerchantOrder(db.Model):
    __tablename__ = 'merchant_orders'

    id = db.Column(db.Integer, primary_key=True)
    merchant_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    client_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    product_id = db.Column(db.Integer, db.ForeignKey('merchant_products.id'), nullable=True)
    product_name = db.Column(db.String(120), nullable=False)
    product_image = db.Column(db.String(255), nullable=True)
    product_image_data = db.Column(db.LargeBinary, nullable=True)
    product_image_mime = db.Column(db.String(60), nullable=True)
    unit_price = db.Column(db.Float, nullable=False)
    quantity = db.Column(db.Integer, nullable=False)
    total_price = db.Column(db.Float, nullable=False)
    payment_phone_from = db.Column(db.String(20), nullable=True)
    payment_screenshot = db.Column(db.String(255), nullable=True)
    payment_screenshot_data = db.Column(db.LargeBinary, nullable=True)
    payment_screenshot_mime = db.Column(db.String(60), nullable=True)
    buyer_name = db.Column(db.String(120), nullable=True)
    notes = db.Column(db.Text, nullable=True)
    status = db.Column(db.String(20), nullable=False, default='pending')
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    merchant = db.relationship('User', foreign_keys=[merchant_id], backref='merchant_sales', lazy=True)
    client = db.relationship('User', foreign_keys=[client_id], backref='product_orders', lazy=True)
    product = db.relationship('MerchantProduct', backref='orders', lazy=True)

    def to_dict(self):
        return {
            'id': self.id,
            'merchant_id': self.merchant_id,
            'merchant_name': self.merchant.name if self.merchant else None,
            'merchant_contact_phone': self.merchant.merchant_contact_phone if self.merchant else None,
            'merchant_payment_phone': self.merchant.merchant_payment_phone if self.merchant else None,
            'merchant_payment_methods': [
                method.to_dict()
                for method in (self.merchant.merchant_payment_methods if self.merchant else [])
                if method.is_active
            ],
            'client_id': self.client_id,
            'client_name': self.client.name if self.client else None,
            'client_phone': self.client.phone if self.client else None,
            'product_id': self.product_id,
            'product_name': self.product_name,
            'product_image': (
                media_url('merchant-orders', self.id, 'product_image')
                if self.product_image_data else self.product_image
            ),
            'unit_price': self.unit_price,
            'quantity': self.quantity,
            'total_price': self.total_price,
            'payment_phone_from': self.payment_phone_from,
            'payment_screenshot': (
                media_url('merchant-orders', self.id, 'payment_screenshot')
                if self.payment_screenshot_data else self.payment_screenshot
            ),
            'buyer_name': self.buyer_name,
            'notes': self.notes,
            'status': self.status,
            'created_at': self.created_at.isoformat(),
            'updated_at': self.updated_at.isoformat() if self.updated_at else None,
        }
