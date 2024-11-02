# utils.py

import logging
from typing import Any, Dict

logger = logging.getLogger(__name__)

def setup_logging():
    logging.basicConfig(level=logging.INFO)
    return logging.getLogger(__name__)

def handle_error(message):
    logger.error(message)
    raise Exception(message)
