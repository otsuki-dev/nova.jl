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
    dot_idx = findlast(==('.'), filename)
    if dot_idx === nothing
        return "application/octet-stream"
    end
    
    ext = lowercase(SubString(filename, dot_idx + 1))
    
    return get(MIME_TYPES, ext, "application/octet-stream")
end

const MIME_TYPES = Dict(
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
