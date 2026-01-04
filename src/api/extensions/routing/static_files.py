"""Static files serving"""

from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles


from src.config import app_config
from src.utils.logger import logger


def init_static_files(app: FastAPI) -> None:
    """Initialize static files serving if static directory exists."""
    static_dir = app_config.STATIC_DIR
    if static_dir.exists():
        app.mount("/static", StaticFiles(directory=static_dir), name="static")
        logger.info("Static files mounted from %s", static_dir)
    else:
        logger.warning(
            "Static directory '%s' does not exist, skipping static files",
            static_dir,
        )
