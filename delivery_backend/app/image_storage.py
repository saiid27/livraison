from pathlib import Path

IMAGE_MIME_BY_EXTENSION = {
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.png': 'image/png',
    '.webp': 'image/webp',
}


def read_image_upload(upload):
    extension = Path(upload.filename or '').suffix.lower()
    mime_type = IMAGE_MIME_BY_EXTENSION.get(extension)
    if not mime_type:
        raise ValueError('Format image non pris en charge')

    image_data = upload.read()
    if not image_data:
        raise ValueError('Image vide')
    return image_data, mime_type
