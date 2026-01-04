"""Package with api extensions"""

from .exception_handlers import init_exception_handlers
from .middlewares import init_cors, add_processing_time_header, init_user_context
from .rate_limiter import init_rate_limiter, close_rate_limiter
from .routing.static_files import init_static_files

__all__ = [
    "init_cors",
    "add_processing_time_header",
    "init_exception_handlers",
    "init_rate_limiter",
    "close_rate_limiter",
    "init_static_files",
    "init_user_context",
]
