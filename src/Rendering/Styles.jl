"""
    Rendering.Styles

Module for handling CSS and SCSS styles, including automatic loading and SCSS processing.
"""

# Cache for processed styles
# Map: styles_dir => (last_check_time, content)
const STYLE_CACHE = Dict{String, Tuple{Float64, String}}()

# Already exported by Nova.jl

"""
    minify_css(css_content::String) -> String

Minifies CSS content by removing whitespace, newlines, and comments.
"""
function minify_css(css_content::String)
    # Remove comments
    css = replace(css_content, r"/\*.*?\*/"s => "")
    # Remove newlines and multiple spaces
    css = replace(css, r"\s+" => " ")
    # Remove space around special characters
    css = replace(css, r"\s*([:;{}])\s*" => s"\1")
    # Remove last semicolon in block
    css = replace(css, r";}" => "}")
    return strip(css)
end

"""
    process_scss(scss_content::String) -> String

Basic SCSS processor that handles variables and comments.
Converts SCSS syntax to CSS by:
- Removing comments
- Processing variables (\$variable)
- Converting to standard CSS

# Examples
```julia
scss = "\$color: #333; body { color: \$color; }"
css = process_scss(scss)
```
"""
function process_scss(scss_content::String)
    css_content = scss_content
    
    # Remove comments
    css_content = replace(css_content, r"//.*$"m => "")
    
    # Extract variables
    variables = Dict{String, String}()
    for line in split(css_content, '\n')
        if startswith(strip(line), '$') && contains(line, ':')
            parts = split(line, ':')
            if length(parts) >= 2
                var_name = strip(parts[1])
                var_value = strip(replace(parts[2], ';' => ""))
                variables[var_name] = var_value
            end
        end
    end
    
    # Replace variables
    for (var, value) in variables
        css_content = replace(css_content, var => value)
    end
    
    # Remove variable declarations
    css_content = replace(css_content, r"^\s*\$.*$"m => "")
    
    return css_content
end

"""
    clear_style_cache()

Clears the style cache. Call this when style files change.
"""
function clear_style_cache()
    empty!(STYLE_CACHE)
end

"""
    auto_load_styles(styles_dir::String="styles") -> String

Automatically loads all CSS and SCSS files from the specified directory
and returns them wrapped in a <style> tag.
Uses caching for performance.

# Examples
```julia
styles_html = auto_load_styles()
styles_html = auto_load_styles("custom_styles")
```
"""
function auto_load_styles(styles_dir::String="styles")
    # Check cache first
    if haskey(STYLE_CACHE, styles_dir)
        return STYLE_CACHE[styles_dir][2]
    end

    styles_content = ""
    
    if !isdir(styles_dir)
        return ""
    end
    
    for file in readdir(styles_dir)
        if endswith(file, ".css") || endswith(file, ".scss")
            file_path = joinpath(styles_dir, file)
            try
                content = read(file_path, String)
                
                if endswith(file, ".scss")
                    content = process_scss(content)
                end
                
                # Minify for production/efficiency
                content = minify_css(content)
                
                styles_content *= content
            catch e
                @warn "Error loading style $file: $e"
            end
        end
    end
    
    result = isempty(styles_content) ? "" : """<style>\n$styles_content\n</style>"""
    
    # Update cache (store current time as placeholder for now)
    STYLE_CACHE[styles_dir] = (time(), result)
    
    return result
end
