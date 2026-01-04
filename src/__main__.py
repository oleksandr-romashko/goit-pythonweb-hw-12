"""
Local / Debug entrypoint for running the FastAPI application.

Allows running the FastAPI application with the same configuration
as Docker (same .env, same port), but with debugger attached.

⚠️ This file is NOT used in Docker or production environments.
It exists solely for:
- local development
- VS Code debugging
- running `python -m src` (See: PEP 338) outside containers
"""

import os
import uvicorn

from src.config import app_config


def main() -> None:
    """Run FastAPI app locally or using debugger"""
    dev_mode = os.getenv("APP_ENV", "prod") == "dev"
    uvicorn.run(
        "src.main:create_app",
        host="0.0.0.0",
        port=app_config.WEB_PORT,
        reload=dev_mode,
        log_level="debug" if dev_mode else "info",
    )


if __name__ == "__main__":
    main()
