import hmac
from hashlib import sha256

from flask import current_app


def media_access_key(collection, item_id, field):
    secret = current_app.config['SECRET_KEY']
    message = f'{collection}:{item_id}:{field}'.encode('utf-8')
    return hmac.new(secret.encode('utf-8'), message, sha256).hexdigest()[:32]


def media_url(collection, item_id, field):
    key = media_access_key(collection, item_id, field)
    return f'/api/media/{collection}/{item_id}/{field}?key={key}'


def is_valid_media_key(collection, item_id, field, key):
    if not key:
        return False
    expected = media_access_key(collection, item_id, field)
    return hmac.compare_digest(expected, key)
