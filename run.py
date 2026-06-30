"""Render entry point when the repository root is used as the service root."""

import sys
from pathlib import Path

backend_directory = Path(__file__).resolve().parent / 'delivery_backend'
sys.path.insert(0, str(backend_directory))

from app import create_app  # noqa: E402

app = create_app()
