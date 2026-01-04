"""
Main module with entry point for the FastAPI application.

Allows to create app instance and initialize FastAPI app,
register all routers, and configure global exception handlers.
"""

from contextlib import asynccontextmanager
from typing import AsyncIterator

from fastapi import FastAPI, Depends

from src.api.extensions import (
    add_processing_time_header,
    close_rate_limiter,
    init_cors,
    init_exception_handlers,
    init_rate_limiter,
    init_static_files,
    init_user_context,
)
from src.api.extensions.rate_limiter import get_rate_limit, RateLimit
from src.api.routers import (
    auth_router,
    contacts_router,
    me_router,
    root_router,
    users_router,
    utils_router,
)
from src.config import app_config
from src.utils.logger import logger

# TODO: Separate .env settings into separate env vars for each service (reduce over-sharing secrets between services even if duplication)
# TODO: Create possibility to invalidate access tokens (e.g. on password change)
# TODO: Add superadmin app management endpoints to disable registration, sending emails, serving web, cache, etc.
# TODO: Add feature - blacklist (cached)
# TODO: Add feature - whitelist set in .env for trusted resources omitting additional checks
# TODO: Clean up User account that was not confirmed (email confirmation) within X hours/days


@asynccontextmanager
async def app_lifespan(
    app: FastAPI,  # pylint: disable=unused-argument
) -> AsyncIterator[None]:
    """
    Application lifespan context manager.

    Runs once on startup and shutdown.
    Resource initialization or cleanup tasks are located here
    (e.g., start/stop logging, cache and other connections).
    """
    logger.info(
        "Application startup initiated on %s:%s", "0.0.0.0", app_config.WEB_PORT
    )
    await init_rate_limiter()
    yield
    await close_rate_limiter()
    logger.info("Application shutdown complete")


def configure_middlewares(app: FastAPI) -> None:
    """Configures application middlewares"""
    # CORS middleware
    init_cors(app)

    # User context middleware
    init_user_context(app)

    # Processing time header middleware for DEV mode
    if app_config.DEV_ENV:
        add_processing_time_header(app)


def configure_exception_handlers(app: FastAPI) -> None:
    """
    Configures application exception handlers
    for common errors and consistent errors response
    """
    init_exception_handlers(app)


def configure_routes(app: FastAPI) -> None:
    """Configures application routes"""
    # Static files serving
    init_static_files(app)

    # API routers
    app.include_router(root_router)
    app.include_router(utils_router, prefix="/api")
    app.include_router(auth_router, prefix="/api")
    app.include_router(users_router, prefix="/api")
    app.include_router(me_router, prefix="/api")
    app.include_router(contacts_router, prefix="/api")


def create_app() -> FastAPI:
    """Creates and instance of FastAPI application"""
    app = FastAPI(
        lifespan=app_lifespan,
        dependencies=[Depends(get_rate_limit(RateLimit.GLOBAL))],
        title=app_config.APP_TITLE,
        version=app_config.APP_VERSION,
        description=app_config.APP_DESCRIPTION,
        contact=app_config.APP_CONTACT,
        license_info=app_config.APP_LICENSE_INFO,
        # https://swagger.io/docs/open-source-tools/swagger-ui/usage/configuration/
        swagger_ui_parameters={
            "persistAuthorization": False,
            "tryItOutEnabled": False,
            "displayRequestDuration": True,
            "syntaxHighlight": {"theme": "agate"},
            "docExpansion": "list",
            "defaultModelsExpandDepth": -1,  # Hides schemas section completely
        },
    )
    configure_middlewares(app)
    configure_exception_handlers(app)
    configure_routes(app)
    return app
