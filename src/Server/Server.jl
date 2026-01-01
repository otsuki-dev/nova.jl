"""
    Server.Server

Core HTTP server module using HTTP.jl as the base.
Provides a clean, modular server implementation.
"""

# Already exported by Nova.jl
# Uses route_to_file, handle_page_route from Router.jl and serve_static from Assets.jl

const HTML_HEADERS = ["Content-Type" => "text/html"]
const HTML_HEADERS_CACHED = ["Content-Type" => "text/html", "Cache-Control" => "max-age=60"]

"""
    create_handler(; pages_dir::Union{String,Nothing}=nothing, public_dir::String="public", api_dir::Union{String,Nothing}=nothing) -> Function

Creates an HTTP request handler function.
The handler processes requests and returns appropriate responses.

# Arguments
- `pages_dir`: Directory containing page files. Defaults to "src/pages" if it exists, otherwise "pages".
- `public_dir`: Directory containing static files (default: "public").
- `api_dir`: Directory containing api files. Defaults to "src/pages/api" if it exists, otherwise "api".

# Examples
```julia
handler = create_handler()
handler = create_handler(pages_dir="views", public_dir="assets")
```
"""
function create_handler(; pages_dir::Union{String,Nothing}=nothing, public_dir::String="public", api_dir::Union{String,Nothing}=nothing)
    # Smart defaults for pages_dir
    if pages_dir === nothing
        if isdir(joinpath("src", "pages"))
            pages_dir = joinpath("src", "pages")
        else
            pages_dir = "pages"
        end
    end

    # Smart defaults for api_dir
    if api_dir === nothing
        # If pages is in src/pages, api should default to src/pages/api (Next.js style)
        if pages_dir == joinpath("src", "pages") && isdir(joinpath("src", "pages", "api"))
            api_dir = joinpath("src", "pages", "api")
        elseif isdir("api")
            api_dir = "api"
        else
            # Fallback to pages_dir/api if it exists
            possible_api = joinpath(pages_dir, "api")
            api_dir = isdir(possible_api) ? possible_api : "api"
        end
    end

    return function(req::HTTP.Request)
        try
            # Fast path: Static routes (when registered)
            # This is the primary code path for production builds
            if ROUTES_REGISTERED[]
                static_handler, static_params = match_static_route(req.target)
                if static_handler !== nothing
                    result = static_handler(req, static_params)
                    if result isa HTTP.Response
                        return result
                    else
                        return HTTP.Response(200, HTML_HEADERS_CACHED, string(result))
                    end
                end
                
                # Check for static files
                if req.target != "/" && contains(req.target, ".")
                    static_response = serve_static(req.target, public_dir)
                    if static_response !== nothing
                        return static_response
                    end
                end
            else
                # Slow path: Development mode with file system scanning
                # 1. Try to serve static files first
                if req.target != "/" && contains(req.target, ".")
                    static_response = serve_static(req.target, public_dir)
                    if static_response !== nothing
                        return static_response
                    end
                end
                
                # 2. Try to route to a page file (Dev/Fallback)
                page_file, params = match_route(req.target, pages_dir, api_dir)
                if page_file !== nothing
                    result = handle_page_route(page_file, params, req)
                    if result !== nothing
                        # If handler returns HTTP.Response (e.g., for APIs), return it directly
                        if result isa HTTP.Response
                            return result
                        else
                            # Otherwise, treat as HTML string
                            return HTTP.Response(200, HTML_HEADERS, string(result))
                        end
                    end
                end
            end
            
            # 3. Return 404 if nothing matched
            # Try to find a custom 404 page
            not_found_file = joinpath(pages_dir, "404.jl")
            if isfile(not_found_file)
                result = handle_page_route(not_found_file, Dict{String,String}(), req)
                if result !== nothing
                    if result isa HTTP.Response
                        return result
                    else
                        return HTTP.Response(404, ["Content-Type" => "text/html"], string(result))
                    end
                end
            end

            # Throw NotFoundError which will be caught and formatted
            throw(NotFoundError(string(req.target)))
        catch e
            error_exception = isa(e, ServerError) ? e : ServerError(string(typeof(e).__name__), string(e))
            return handle_error(error_exception, 500; request=req, dev_mode=false)
        end
    end
end

"""
    start_server(handler=create_handler(); host::String="127.0.0.1", port::Int=2518, verbose::Bool=true)

Starts the HTTP server with the given handler.

# Arguments
- `handler`: Request handler function (default: create_handler())
- `host::String`: Server host address (default: "127.0.0.1")
- `port::Int`: Server port (default: 2518)
- `verbose::Bool`: Whether to show startup messages (default: true)

# Examples
```julia
# Start with defaults
start_server()

# Start on custom port
start_server(port=3000)

# Start with custom handler
my_handler = create_handler(pages_dir="views")
start_server(my_handler, port=3000)
```
"""
function start_server(handler=create_handler(); 
                     host::String="127.0.0.1", 
                     port::Int=2518,
                     verbose::Bool=true)
    
    if verbose
        printstyled("  ⚡  ", color=:green, bold=true)
        printstyled("Nova.jl Server starting...", color=:white, bold=true)
        println()
        printstyled("  →  ", color=:cyan, bold=true)
        printstyled("Listening on ", color=:light_black)
        printstyled("http://$host:$port", color=:cyan)
        println()
        printstyled("  ℹ  ", color=:blue)
        printstyled("Press Ctrl+C to stop", color=:light_black)
        println()
    end
    
    try
        # Optimizations for high throughput
        HTTP.serve(handler, host, port; 
            verbose=false, 
            access_log=nothing, 
            reuseaddr=true, 
            tcp_nodelay=true
        )
    catch e
        if isa(e, InterruptException)
            # Saída sutil ao parar o servidor (apenas uma linha em branco)
            println()
        else
            printstyled("  ✗  ", color=:red, bold=true)
            printstyled("Server error: ", color=:light_black)
            printstyled("$e", color=:red)
            println()
            rethrow(e)
        end
    end
end
