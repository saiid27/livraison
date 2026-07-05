from flask import Flask, send_from_directory, send_file, jsonify, render_template_string
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


SUPPORT_PAGE_TEMPLATE = """
<!doctype html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>الدعم - mayahsar</title>
  <style>
    :root { color-scheme: light; }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      min-height: 100vh;
      display: grid;
      place-items: center;
      padding: 22px;
      background: #f6f8fc;
      color: #172033;
      font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
    }
    main {
      width: min(460px, 100%);
      background: white;
      border: 1px solid #e5eaf3;
      border-radius: 18px;
      padding: 22px;
      box-shadow: 0 18px 45px rgba(23, 32, 51, 0.08);
      text-align: center;
    }
    .mark {
      width: 72px;
      height: 72px;
      margin: 0 auto 14px;
      display: grid;
      place-items: center;
      border-radius: 22px;
      background: #eaf1ff;
      color: #2563eb;
      font-size: 34px;
      font-weight: 900;
    }
    h1 { margin: 0; font-size: 28px; }
    p { margin: 10px 0 18px; color: #667085; line-height: 1.7; }
    .phone {
      margin: 18px 0;
      padding: 14px;
      border-radius: 14px;
      background: #f8fafc;
      border: 1px solid #e2e8f0;
      direction: ltr;
      font-size: 24px;
      font-weight: 900;
      letter-spacing: 0.5px;
    }
    .actions { display: grid; gap: 10px; }
    a {
      display: block;
      text-decoration: none;
      padding: 14px 16px;
      border-radius: 14px;
      font-weight: 900;
    }
    .whatsapp { background: #16a34a; color: white; }
    .call { background: #2563eb; color: white; }
    .muted { margin-top: 16px; font-size: 13px; color: #94a3b8; }
  </style>
</head>
<body>
  <main>
    <div class="mark">?</div>
    <h1>الدعم والمساعدة</h1>
    <p>لأي مشكلة في الطلبات أو الحسابات، تواصل معنا عبر رقم المركز.</p>
    <div class="phone">+222 43 76 01 28</div>
    <div class="actions">
      <a class="whatsapp" href="https://wa.me/22243760128">فتح واتساب</a>
      <a class="call" href="tel:+22243760128">اتصال بالمركز</a>
    </div>
    <div class="muted">mayahsar support</div>
  </main>
</body>
</html>
"""


PRIVACY_PAGE_TEMPLATE = """
<!doctype html>
<html lang="fr" dir="ltr">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Politique de confidentialité - mayahsar</title>
  <style>
    * { box-sizing: border-box; }
    body {
      margin: 0;
      background: #f6f8fc;
      color: #172033;
      font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      line-height: 1.7;
    }
    header { background: #2563eb; color: white; padding: 28px 20px; text-align: center; }
    main { max-width: 860px; margin: 0 auto; padding: 22px; }
    section {
      background: white;
      border: 1px solid #e5eaf3;
      border-radius: 16px;
      padding: 18px;
      margin-bottom: 14px;
      box-shadow: 0 12px 30px rgba(23, 32, 51, 0.05);
    }
    h1, h2 { margin: 0 0 10px; }
    p { margin: 0; color: #475569; }
    ul { margin: 8px 0 0; color: #475569; }
    a { color: #2563eb; font-weight: 800; }
    .muted { color: #94a3b8; font-size: 13px; text-align: center; margin-top: 18px; }
  </style>
</head>
<body>
  <header>
    <h1>Politique de confidentialité</h1>
    <p>Application mayahsar</p>
  </header>
  <main>
    <section>
      <h2>Informations que nous collectons</h2>
      <p>Nous collectons les informations nécessaires au fonctionnement des services de livraison et des comptes, comme le nom, le numéro de téléphone, le type de compte, les détails des commandes, ainsi que les images de paiement ou les documents lorsque cela est nécessaire.</p>
    </section>
    <section>
      <h2>Utilisation des informations</h2>
      <p>Nous utilisons ces informations pour créer les comptes, traiter les commandes, communiquer avec les utilisateurs, vérifier les comptes des capitaines et des commerçants, et améliorer la sécurité du service.</p>
    </section>
    <section>
      <h2>Images et documents</h2>
      <p>Les utilisateurs peuvent importer des images comme des preuves de paiement, des photos de produits ou des documents de capitaine. Ces fichiers sont utilisés uniquement pour la vérification et le fonctionnement du service.</p>
    </section>
    <section>
      <h2>Partage des données</h2>
      <p>Nous ne vendons pas les données des utilisateurs. Certaines informations nécessaires à une commande peuvent être partagées uniquement avec la partie concernée, comme le capitaine ou le commerçant, afin de finaliser le service.</p>
    </section>
    <section>
      <h2>Suppression du compte</h2>
      <p>L'utilisateur peut demander la suppression de son compte depuis l'application ou en contactant le support. Nous examinerons la demande et supprimerons les données conformément aux exigences opérationnelles et légales applicables.</p>
    </section>
    <section>
      <h2>Nous contacter</h2>
      <p>Pour toute question concernant la confidentialité, contactez-nous au +222 43 76 01 28 ou via la <a href="/support">page de support</a>.</p>
    </section>
    <div class="muted">Dernière mise à jour : 2026</div>
  </main>
</body>
</html>
"""


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

    @app.route('/support')
    @app.route('/api/support')
    def support_page():
        return render_template_string(SUPPORT_PAGE_TEMPLATE)

    @app.route('/privacy')
    @app.route('/api/privacy')
    def privacy_page():
        return render_template_string(PRIVACY_PAGE_TEMPLATE)

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
        from app.models.delivery_pricing import DeliveryLocation, DeliveryPrice  # noqa: F401
        from app.models.user import User
        from app.delivery_locations import seed_default_delivery_locations

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
        seed_default_delivery_locations()

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
            "ALTER TABLE users ADD COLUMN IF NOT EXISTS avatar_data BYTEA",
            "ALTER TABLE users ADD COLUMN IF NOT EXISTS avatar_mime VARCHAR(60)",
            "ALTER TABLE users ADD COLUMN IF NOT EXISTS id_card_image_data BYTEA",
            "ALTER TABLE users ADD COLUMN IF NOT EXISTS id_card_image_mime VARCHAR(60)",
            "ALTER TABLE users ADD COLUMN IF NOT EXISTS vehicle_image_data BYTEA",
            "ALTER TABLE users ADD COLUMN IF NOT EXISTS vehicle_image_mime VARCHAR(60)",
            "ALTER TABLE users ADD COLUMN IF NOT EXISTS vehicle_registration_image_data BYTEA",
            "ALTER TABLE users ADD COLUMN IF NOT EXISTS vehicle_registration_image_mime VARCHAR(60)",
            "ALTER TABLE users ADD COLUMN IF NOT EXISTS permit_image_data BYTEA",
            "ALTER TABLE users ADD COLUMN IF NOT EXISTS permit_image_mime VARCHAR(60)",
            "ALTER TABLE users ADD COLUMN IF NOT EXISTS approval_status VARCHAR(20) NOT NULL DEFAULT 'approved'",
            "ALTER TABLE users ADD COLUMN IF NOT EXISTS reset_code VARCHAR(6)",
            "ALTER TABLE users ADD COLUMN IF NOT EXISTS reset_code_expires_at TIMESTAMP",
            "ALTER TABLE users ADD COLUMN IF NOT EXISTS otp_requested_at TIMESTAMP",
            "ALTER TABLE users ADD COLUMN IF NOT EXISTS otp_verified_at TIMESTAMP",
            "ALTER TABLE users ADD COLUMN IF NOT EXISTS is_developer BOOLEAN NOT NULL DEFAULT FALSE",
            "ALTER TABLE orders ALTER COLUMN price DROP NOT NULL",
            "ALTER TABLE orders ADD COLUMN IF NOT EXISTS service_type VARCHAR(20) NOT NULL DEFAULT 'delivery'",
            "ALTER TABLE orders ADD COLUMN IF NOT EXISTS manual_customer_name VARCHAR(120)",
            "ALTER TABLE orders ADD COLUMN IF NOT EXISTS manual_customer_phone VARCHAR(20)",
            "ALTER TABLE orders ADD COLUMN IF NOT EXISTS picked_up_at TIMESTAMP",
            "ALTER TABLE orders ADD COLUMN IF NOT EXISTS commission_charged_at TIMESTAMP",
            "ALTER TABLE orders ADD COLUMN IF NOT EXISTS commission_amount FLOAT",
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
            "ALTER TABLE payment_methods ADD COLUMN IF NOT EXISTS logo VARCHAR(255)",
            "ALTER TABLE cash_transactions ADD COLUMN IF NOT EXISTS order_id INTEGER",
        ):
            db.session.execute(text(statement))
        db.session.execute(text("""
            UPDATE users
            SET is_developer = TRUE
            WHERE role = 'admin'
            AND id = (
                SELECT id FROM users
                WHERE role = 'admin'
                ORDER BY id ASC
                LIMIT 1
            )
            AND NOT EXISTS (
                SELECT 1 FROM users
                WHERE role = 'admin'
            AND is_developer = TRUE
            )
        """))
        image_fields = {
            'avatar': ('avatar_data', 'avatar_mime'),
            'id_card_image': ('id_card_image_data', 'id_card_image_mime'),
            'vehicle_image': ('vehicle_image_data', 'vehicle_image_mime'),
            'vehicle_registration_image': (
                'vehicle_registration_image_data',
                'vehicle_registration_image_mime',
            ),
            'permit_image': ('permit_image_data', 'permit_image_mime'),
        }
        image_mimes = {
            '.jpg': 'image/jpeg',
            '.jpeg': 'image/jpeg',
            '.png': 'image/png',
            '.webp': 'image/webp',
        }
        captains = User.query.filter(
            User.role.in_(('livreur', 'car_captain'))
        ).all()
        for captain in captains:
            for path_attr, (data_attr, mime_attr) in image_fields.items():
                if getattr(captain, data_attr):
                    continue
                image_path = getattr(captain, path_attr)
                if not image_path or image_path.startswith('/api/auth/images/'):
                    continue
                if not image_path.startswith('/uploads/'):
                    continue
                local_path = os.path.join(
                    app.config['UPLOAD_FOLDER'],
                    image_path.removeprefix('/uploads/'),
                )
                if not os.path.exists(local_path):
                    continue
                with open(local_path, 'rb') as image_file:
                    setattr(captain, data_attr, image_file.read())
                ext = os.path.splitext(local_path)[1].lower()
                setattr(captain, mime_attr, image_mimes.get(ext, 'image/jpeg'))
                setattr(
                    captain,
                    path_attr,
                    f'/api/auth/images/{captain.id}/{path_attr}',
                )
        db.session.commit()

    return app
