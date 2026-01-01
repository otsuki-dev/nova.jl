"""
    Rendering.Assets

Module for handling static assets like images, fonts, and other files.
"""

# Already exported by Nova.jl
# Uses get_mime_type from Utils/MIME.jl

"""
    serve_static(request_path::String, public_dir::String="public") -> Union{HTTP.Response, Nothing}

Serves static files from the public directory.
Returns an HTTP.Response if the file exists, or nothing if not found.

# Examples
```julia
response = serve_static("/logo.png")
response = serve_static("/images/photo.jpg", "assets")
```
"""
function serve_static(request_path::String, public_dir::String="public")
    clean_path = lstrip(request_path, '/')
    
    # Security check: Prevent path traversal
    # Resolve absolute paths
    abs_public_dir = abspath(public_dir)
    public_file = joinpath(public_dir, clean_path)
    abs_public_file = abspath(public_file)
    
    # Check if the resolved file path starts with the resolved public directory path
    if !startswith(abs_public_file, abs_public_dir)
        @warn "Security Alert: Path traversal attempt blocked: $request_path"
        return nothing
    end
    
    if !isfile(public_file)
        return nothing
    end
    
    try
        mime_type = get_mime_type(public_file)
        
        # Binary files (images, fonts, etc.)
        headers = [
            "Content-Type" => mime_type,
            "Cache-Control" => "public, max-age=3600",
            "Access-Control-Allow-Origin" => "*"
        ]
        
        if startswith(mime_type, "image/") || 
           startswith(mime_type, "font/") || 
           mime_type == "application/octet-stream"
            content = read(public_file)
            return HTTP.Response(200, headers, content)
        else
            # Text files
            content = read(public_file, String)
            return HTTP.Response(200, headers, content)
        end
    catch e
        @warn "Error serving file $public_file: $e"
        return nothing
    end
end

"""
    auto_favicon(public_dir::String="public") -> String

Automatically detects and returns HTML link tag for favicon files.
Searches for common favicon file names in the public directory.

# Examples
```julia
favicon_html = auto_favicon()
favicon_html = auto_favicon("assets")
```
"""
function auto_favicon(public_dir::String="public")
    favicon_files = [
        ("logo.svg", "image/svg+xml"),
        ("favicon.svg", "image/svg+xml"),
        ("favicon.ico", "image/x-icon"),
        ("favicon.png", "image/png"),
        ("icon.svg", "image/svg+xml"),
        ("icon.ico", "image/x-icon"),
        ("icon.png", "image/png")
    ]
    
    for (filename, mime_type) in favicon_files
        if isfile(joinpath(public_dir, filename))
            return """<link rel="icon" type="$mime_type" href="/$filename">"""
        end
    end
    
    return ""
end
