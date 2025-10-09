"""
    Rendering.Styles

Module for handling CSS and SCSS styles, including automatic loading and SCSS processing.
"""

# Already exported by Nova.jl

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
    auto_load_styles(styles_dir::String="styles") -> String

Automatically loads all CSS and SCSS files from the specified directory
and returns them wrapped in a <style> tag.

# Examples
```julia
styles_html = auto_load_styles()
styles_html = auto_load_styles("custom_styles")
```
"""
function auto_load_styles(styles_dir::String="styles")
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
                
                styles_content *= "\n" * content
            catch e
                @warn "Error loading style $file: $e"
            end
        end
    end
    
    return isempty(styles_content) ? "" : """<style>\n$styles_content\n</style>"""
end
