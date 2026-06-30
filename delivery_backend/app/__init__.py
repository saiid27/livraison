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

    db.init_app(app)
    jwt.init_app(app)
    bcrypt.init_app(app)
    CORS(app, resources={r"/api/*": {"origins": "*"}})

    from app.routes.auth import auth_bp
    from app.routes.client import client_bp
    from app.routes.livreur import livreur_bp
    from app.routes.admin import admin_bp

    app.register_blueprint(auth_bp, url_prefix='/api/auth')
    app.register_blueprint(client_bp, url_prefix='/api/client')
    app.register_blueprint(livreur_bp, url_prefix='/api/livreur')
    app.register_blueprint(admin_bp, url_prefix='/api/admin')

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
        enum_exists = db.session.execute(
            text("SELECT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role')")
        ).scalar()
        if enum_exists:
            db.session.execute(
                text("ALTER TYPE user_role ADD VALUE IF NOT EXISTS 'merchant'")
            )
            db.session.commit()

        db.create_all()

        # Lightweight development migration for existing databases.
        for statement in (
            "ALTER TABLE users ADD COLUMN IF NOT EXISTS id_card_image VARCHAR(255)",
            "ALTER TABLE users ADD COLUMN IF NOT EXISTS vehicle_image VARCHAR(255)",
            "ALTER TABLE users ADD COLUMN IF NOT EXISTS vehicle_registration_image VARCHAR(255)",
            "ALTER TABLE users ADD COLUMN IF NOT EXISTS permit_image VARCHAR(255)",
            "ALTER TABLE users ADD COLUMN IF NOT EXISTS approval_status VARCHAR(20) NOT NULL DEFAULT 'approved'",
            "ALTER TABLE users ADD COLUMN IF NOT EXISTS reset_code VARCHAR(6)",
            "ALTER TABLE users ADD COLUMN IF NOT EXISTS reset_code_expires_at TIMESTAMP",
            "ALTER TABLE orders ALTER COLUMN price DROP NOT NULL",
            "ALTER TABLE orders ADD COLUMN IF NOT EXISTS service_type VARCHAR(20) NOT NULL DEFAULT 'delivery'",
        ):
            db.session.execute(text(statement))
        db.session.commit()

    return app
