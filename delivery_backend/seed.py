"""Script pour initialiser la base de données avec des données de test."""
from app import create_app, db, bcrypt
from app.models.user import User
from app.models.order import Order

app = create_app()

with app.app_context():
    db.drop_all()
    db.create_all()

    # Créer les utilisateurs
    users = [
        User(
            name='Admin Principal',
            email='admin@delivery.com',
            phone='22000001',
            password_hash=bcrypt.generate_password_hash('admin123').decode('utf-8'),
            role='admin',
        ),
        User(
            name='Developer',
            email='developer@mayahsar.com',
            phone='22000000',
            password_hash=bcrypt.generate_password_hash('developer123').decode('utf-8'),
            role='admin',
        ),
        User(
            name='Mohamed Client',
            email='client@delivery.com',
            phone='22000002',
            password_hash=bcrypt.generate_password_hash('client123').decode('utf-8'),
            role='client',
        ),
        User(
            name='Ahmed Livreur',
            email='livreur@delivery.com',
            phone='22000003',
            password_hash=bcrypt.generate_password_hash('livreur123').decode('utf-8'),
            role='livreur',
            approval_status='approved',
        ),
        User(
            name='Boutique Test',
            email='merchant@delivery.com',
            phone='22000004',
            password_hash=bcrypt.generate_password_hash('merchant123').decode('utf-8'),
            role='merchant',
        ),
    ]
    db.session.add_all(users)
    db.session.commit()

    client = User.query.filter_by(role='client').first()
    livreur = User.query.filter_by(role='livreur').first()

    # Créer des commandes de test
    orders = [
        Order(
            client_id=client.id,
            description='Documents importants à livrer',
            pickup_address='Carrefour Madrid, Nouakchott',
            delivery_address='Ministère des Finances, Tevragh Zeina',
            price=500.0,
            status='en_attente',
        ),
        Order(
            client_id=client.id,
            livreur_id=livreur.id,
            description='Colis fragile - matériel informatique',
            pickup_address='Marché Capitale, Nouakchott',
            delivery_address='Université de Nouakchott',
            price=800.0,
            status='en_cours',
        ),
        Order(
            client_id=client.id,
            livreur_id=livreur.id,
            description='Médicaments urgents',
            pickup_address='Pharmacie Centrale',
            delivery_address='Hay Saken, Nouakchott',
            price=300.0,
            status='livre',
        ),
    ]
    db.session.add_all(orders)
    db.session.commit()

    print("✅ Base de données initialisée avec succès !")
    print("\n📋 Comptes de test :")
    print("  Admin   → admin@delivery.com   / admin123")
    print("  Client  → client@delivery.com  / client123")
    print("  Livreur → livreur@delivery.com / livreur123")
    print("  Developer → developer@mayahsar.com / developer123")
    print("  Commerçant → merchant@delivery.com / merchant123")
