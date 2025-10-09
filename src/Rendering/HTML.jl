"""
    Rendering.HTML

Module for HTML rendering and template generation.
"""

# Already exported by Nova.jl
# Uses auto_load_styles from Styles.jl and auto_favicon from Assets.jl

"""
    render(content::String; auto_styles::Bool=false, title::String="Nova.jl App", lang::String="en") -> String

Renders HTML content within a complete HTML document structure.
By default, NO styles are included to keep the core framework minimal.

# Arguments
- `content::String`: The HTML content to render in the body
- `auto_styles::Bool`: Whether to auto-load styles from styles/ directory (default: false)
- `title::String`: Page title (default: "Nova.jl App")
- `lang::String`: HTML lang attribute (default: "en")

# Examples
```julia
html = render("<h1>Hello World</h1>")
html = render("<h1>Hello</h1>", title="My Page", auto_styles=true)
```
"""
function render(content::String; 
                auto_styles::Bool=false, 
                title::String="Nova.jl App", 
                lang::String="en")
    
    styles_html = auto_styles ? auto_load_styles() : ""
    favicon_html = auto_favicon()
    
    return """
    <!DOCTYPE html>
    <html lang="$lang">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        $favicon_html
        <title>$title</title>
        $styles_html
      </head>
      <body>
        $content
      </body>
    </html>
    """
end
