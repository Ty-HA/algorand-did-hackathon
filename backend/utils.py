# utils.py

import logging

def setup_logging():
    logging.basicConfig(level=logging.INFO)
    return logging.getLogger(__name__)

logger = setup_logging()

def handle_error(message):
    logger.error(message)
    raise Exception(message)
