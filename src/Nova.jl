"""
    Nova

A minimal framework for building fast web applications in Julia.

Nova.jl provides a simple, file-based routing system with automatic hot reloading,
static file serving, and built-in SCSS processing.

Main Modules
- `Server`: HTTP server and routing
- `Rendering`: HTML templates, styles, and assets
- `DevTools`: Hot reload and development utilities
- `Utils`: Helper functions

Quick Start:

using Nova

# Start a server
Nova.start_server(port=2518)
"""

module Nova

using HTTP
using FileWatching
using Dates

# Include all submodule files
include("Utils/MIME.jl")
include("Utils/FileSystem.jl")
include("Utils/ErrorHandler.jl")
include("Utils/Validation.jl")
include("Rendering/Styles.jl")
include("Rendering/Assets.jl")
include("Rendering/Template.jl")
include("Rendering/HTML.jl")
include("Database/DB.jl")
include("Server/Router.jl")
include("Server/Server.jl")
include("DevTools/HotReload.jl")
include("DevTools/Scaffold.jl")
using .Scaffold
using .ErrorHandler
using .Validation

# Export main API
export render, start_server, create_handler
export render_view, render_template
export DB
export auto_load_styles, process_scss, serve_static, auto_favicon, get_mime_type
export watch_and_reload, reload_modules
export route_to_file, handle_page_route, scan_routes, generate_route_file
export register_static_routes, match_static_route, clear_page_cache, clear_style_cache
export create_app

# Export error handling
export NovaException, NotFoundError, ValidationError, ServerError
export handle_error, get_error_page, format_error_message, log_error, init_error_log

# Export validation
export @validate, @validate_one, Validator
export required, email, min_length, max_length, matches, in_list
export validate, validate_data

# Convenience function
greet() = print("Welcome to Nova.jl!")

end
