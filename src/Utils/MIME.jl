"""
    Utils.MIME

Utility module for handling MIME types based on file extensions.
"""

export get_mime_type

"""
    get_mime_type(filename::String) -> String

Returns the MIME type for a given filename based on its extension.
Falls back to "application/octet-stream" for unknown extensions.

# Examples
```julia
get_mime_type("style.css")  # Returns "text/css"
get_mime_type("image.png")  # Returns "image/png"
```
"""
function get_mime_type(filename::String)
    ext = lowercase(split(filename, '.')[end])
    
    mime_types = Dict(
        "html" => "text/html",
        "css" => "text/css",
        "js" => "application/javascript",
        "svg" => "image/svg+xml",
        "png" => "image/png",
        "jpg" => "image/jpeg",
        "jpeg" => "image/jpeg",
        "gif" => "image/gif",
        "ico" => "image/x-icon",
        "json" => "application/json",
        "txt" => "text/plain",
        "woff" => "font/woff",
        "woff2" => "font/woff2",
        "ttf" => "font/ttf",
        "otf" => "font/otf"
    )
    
    return get(mime_types, ext, "application/octet-stream")
end
