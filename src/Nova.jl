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
include("Rendering/Styles.jl")
include("Rendering/Assets.jl")
include("Rendering/HTML.jl")
include("Server/Router.jl")
include("Server/Server.jl")
include("DevTools/HotReload.jl")

# Export main API
export render, start_server, create_handler
export auto_load_styles, process_scss, serve_static, auto_favicon, get_mime_type
export watch_and_reload, reload_modules
export route_to_file, handle_page_route, scan_routes, generate_route_file

# Convenience function
greet() = print("Welcome to Nova.jl!")

end
