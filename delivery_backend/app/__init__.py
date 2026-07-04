from flask import Flask, send_from_directory, send_file, jsonify
from flask_sqlalchemy import SQLAlchemy
from flask_jwt_extended import JWTManager
from flask_bcrypt import Bcrypt
from flask_cors import CORS
from dotenv import load_dotenv
from sqlalchemy import text
import os
from io import BytesIO
from urllib.request import Request, urlopen

load_dotenv()

db = SQLAlchemy()
jwt = JWTManager()
bcrypt = Bcrypt()


def create_app():
    app = Flask(__name__)

    upload_folder = os.path.join(app.root_path, '..', 'uploads')
    os.makedirs(upload_folder, exist_ok=True)

    app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'dev-secret')
    app.config['JWT_SECRET_KEY'] = os.getenv('JWT_SECRET_KEY', 'jwt-secret')
    app.config['SQLALCHEMY_DATABASE_URI'] = os.getenv('DATABASE_URL')
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
    app.config['JWT_ACCESS_TOKEN_EXPIRES'] = False  # tokens sans expiration (dev)
    app.config['UPLOAD_FOLDER'] = os.path.abspath(upload_folder)
    app.config['CHINGUISOFT_VALIDATION_KEY'] = os.getenv(
        'CHINGUISOFT_VALIDATION_KEY'
    )
    app.config['CHINGUISOFT_VALIDATION_TOKEN'] = os.getenv(
        'CHINGUISOFT_VALIDATION_TOKEN'
    )

    db.init_app(app)
    jwt.init_app(app)
    bcrypt.init_app(app)
    CORS(app, resources={r"/api/*": {"origins": "*"}})

    from app.routes.auth import auth_bp
    from app.routes.client import client_bp
    from app.routes.livreur import livreur_bp
    from app.routes.admin import admin_bp
    from app.routes.merchant import merchant_bp

    app.register_blueprint(auth_bp, url_prefix='/api/auth')
    app.register_blueprint(client_bp, url_prefix='/api/client')
    app.register_blueprint(livreur_bp, url_prefix='/api/livreur')
    app.register_blueprint(admin_bp, url_prefix='/api/admin')
    app.register_blueprint(merchant_bp, url_prefix='/api/merchant')

    @app.route('/api/health')
    def health():
        db.session.execute(text('SELECT 1'))
        return jsonify({'status': 'ok'}), 200

    @app.route('/uploads/<path:filename>')
    def uploaded_file(filename):
        return send_from_directory(app.config['UPLOAD_FOLDER'], filename)

    @app.route('/api/map/tiles/<int:zoom>/<int:x>/<int:y>.png')
    def map_tile(zoom, x, y):
        if not 0 <= zoom <= 19:
            return jsonify({'message': 'Niveau de zoom invalide'}), 400

        cache_file = os.path.join(
            app.instance_path, 'map_tiles', str(zoom), str(x), f'{y}.png'
        )
        if os.path.exists(cache_file):
            return send_file(cache_file, mimetype='image/png', max_age=86400)

        try:
            request = Request(
                f'https://tile.openstreetmap.org/{zoom}/{x}/{y}.png',
                headers={'User-Agent': 'MayahsarDelivery/1.0'},
            )
            with urlopen(request, timeout=10) as response:
                tile_data = response.read()
            os.makedirs(os.path.dirname(cache_file), exist_ok=True)
            with open(cache_file, 'wb') as tile:
                tile.write(tile_data)
            return send_file(
                BytesIO(tile_data), mimetype='image/png', max_age=86400
            )
        except Exception:
            return jsonify({'message': 'Tuile indisponible'}), 502

    with app.app_context():
        # Import new models so db.create_all() discovers their tables
        from app.models.payment_method import PaymentMethod  # noqa: F401
        from app.models.recharge_request import RechargeRequest  # noqa: F401
        from app.models.account_deletion_request import AccountDeletionRequest  # noqa: F401
        from app.models.merchant_product import MerchantProduct  # noqa: F401
        from app.models.merchant_order import MerchantOrder  # noqa: F401
        from app.models.merchant_payment_method import MerchantPaymentMethod  # noqa: F401
        from app.models.cash_transaction import CashTransaction  # noqa: F401

        enum_exists = db.session.execute(
            text("SELECT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role')")
        ).scalar()
        if enum_exists:
            db.session.execute(
                text("ALTER TYPE user_role ADD VALUE IF NOT EXISTS 'merchant'")
            )
            db.session.execute(
                text("ALTER TYPE user_role ADD VALUE IF NOT EXISTS 'car_captain'")
            )
            db.session.commit()

        db.create_all()

        db.session.execute(
            text(
                """
                CREATE TABLE IF NOT EXISTS otp_rate_limits (
                    phone VARCHAR(32) PRIMARY KEY,
                    requested_at TIMESTAMP NOT NULL
                )
                """
            )
        )

        # Lightweight development migration for existing databases.
        for statement in (
            "ALTER TABLE users ADD COLUMN IF NOT EXISTS id_card_image VARCHAR(255)",
            "ALTER TABLE users ADD COLUMN IF NOT EXISTS vehicle_image VARCHAR(255)",
            "ALTER TABLE users ADD COLUMN IF NOT EXISTS vehicle_registration_image VARCHAR(255)",
            "ALTER TABLE users ADD COLUMN IF NOT EXISTS permit_image VARCHAR(255)",
            "ALTER TABLE users ADD COLUMN IF NOT EXISTS approval_status VARCHAR(20) NOT NULL DEFAULT 'approved'",
            "ALTER TABLE users ADD COLUMN IF NOT EXISTS reset_code VARCHAR(6)",
            "ALTER TABLE users ADD COLUMN IF NOT EXISTS reset_code_expires_at TIMESTAMP",
            "ALTER TABLE users ADD COLUMN IF NOT EXISTS otp_requested_at TIMESTAMP",
            "ALTER TABLE users ADD COLUMN IF NOT EXISTS otp_verified_at TIMESTAMP",
            "ALTER TABLE orders ALTER COLUMN price DROP NOT NULL",
            "ALTER TABLE orders ADD COLUMN IF NOT EXISTS service_type VARCHAR(20) NOT NULL DEFAULT 'delivery'",
            "ALTER TABLE users ADD COLUMN IF NOT EXISTS balance FLOAT NOT NULL DEFAULT 0",
            "ALTER TABLE users ADD COLUMN IF NOT EXISTS vehicle_type VARCHAR(10) NOT NULL DEFAULT 'moto'",
            "ALTER TABLE users ADD COLUMN IF NOT EXISTS merchant_contact_phone VARCHAR(20)",
            "ALTER TABLE users ADD COLUMN IF NOT EXISTS merchant_payment_phone VARCHAR(20)",
            "ALTER TABLE orders ADD COLUMN IF NOT EXISTS cancellation_reason TEXT",
            "ALTER TABLE merchant_orders ADD COLUMN IF NOT EXISTS payment_phone_from VARCHAR(20)",
            "ALTER TABLE merchant_orders ADD COLUMN IF NOT EXISTS payment_screenshot VARCHAR(255)",
            "ALTER TABLE merchant_orders ADD COLUMN IF NOT EXISTS buyer_name VARCHAR(120)",
            "ALTER TABLE merchant_orders ADD COLUMN IF NOT EXISTS notes TEXT",
            "ALTER TABLE merchant_products ADD COLUMN IF NOT EXISTS image VARCHAR(255)",
        ):
            db.session.execute(text(statement))
        db.session.commit()

    return app
