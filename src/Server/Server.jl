"""
    Server.Server

Core HTTP server module using HTTP.jl as the base.
Provides a clean, modular server implementation.
"""

# Already exported by Nova.jl
# Uses route_to_file, handle_page_route from Router.jl and serve_static from Assets.jl

"""
    create_handler(; pages_dir::String="pages", public_dir::String="public", api_dir::String="api") -> Function

Creates an HTTP request handler function.
The handler processes requests and returns appropriate responses.

# Arguments
- `pages_dir::String`: Directory containing page files (default: "pages")
- `public_dir::String`: Directory containing static files (default: "public")
- `api_dir::String`: Directory containing api files (default: "api")

# Examples
```julia
handler = create_handler()
handler = create_handler(pages_dir="views", public_dir="assets")
```
"""
function create_handler(; pages_dir::String="pages", public_dir::String="public", api_dir::String="api")
    return function(req::HTTP.Request)
        try
            # 1. Try to serve static files first
            static_response = serve_static(req.target, public_dir)
            if static_response !== nothing
                return static_response
            end
            
            # 2. Try static routes (AOT/Production)
            # This is much faster than filesystem scanning
            static_handler, static_params = match_static_route(req.target)
            if static_handler !== nothing
                try
                    result = static_handler(req, static_params)
                    if result isa HTTP.Response
                        return result
                    else
                        return HTTP.Response(200, ["Content-Type" => "text/html"], string(result))
                    end
                catch e
                    @error "Error in static handler: $e"
                    rethrow(e)
                end
            end

            # 3. Try to route to a page file (Dev/Fallback)
            page_file, params = match_route(req.target, pages_dir, api_dir)
            if page_file !== nothing
                result = handle_page_route(page_file, params, req)
                if result !== nothing
                    # If handler returns HTTP.Response (e.g., for APIs), return it directly
                    if result isa HTTP.Response
                        return result
                    else
                        # Otherwise, treat as HTML string
                        return HTTP.Response(200, ["Content-Type" => "text/html"], string(result))
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

            return HTTP.Response(404, """
            <html><body>
            <h1>404 - Page Not Found</h1>
            <p>The page you're looking for doesn't exist.</p>
            <a href="/">Back to home</a>
            </body></html>
            """)
        catch e
            @error "Request error: $e"
            return HTTP.Response(500, """
            <html><body>
            <h1>500 - Server Error</h1>
            <pre>$e</pre>
            <p><a href="/">Back to home</a></p>
            </body></html>
            """)
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
        HTTP.serve(handler, host, port)
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
