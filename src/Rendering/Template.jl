"""
    Rendering.Template

Module for handling template rendering using a simple custom engine.
Supports {{variable}} and {{#section}}...{{/section}} for lists and booleans.
"""

# Already exported by Nova.jl

"""
    render_view(template::AbstractString, data::Dict) -> String

Renders a template string with the provided data.

# Arguments
- `template::AbstractString`: The template string
- `data::Dict`: Dictionary of data to pass to the template

# Supported Syntax
- `{{key}}`: Insert value of `key`
- `{{#key}}...{{/key}}`: Section.
  - If `key` is a list, repeats content for each item.
  - If `key` is true/truthy, shows content.
  - If `key` is false/missing, hides content.
"""
function render_view(template::AbstractString, data::Dict)
    result = template
    
    # 1. Handle sections {{#key}}...{{/key}}
    # Regex for non-nested sections
    section_regex = r"\{\{#(\w+)\}\}([\s\S]*?)\{\{/\1\}\}"
    
    # We use a loop to handle nested sections (by processing inner ones in recursive calls)
    # But replace goes left to right.
    # To handle nested, we might need to be careful.
    # This simple implementation might not handle deep nesting perfectly in one pass if regex is greedy.
    # But `[\s\S]*?` is non-greedy.
    
    # We keep replacing until no more sections are found to handle nesting?
    # Actually, the recursive call `view(content, item)` handles the inner content.
    # So one pass of replace is enough for top-level sections?
    # No, because regex matches the innermost or outermost?
    # `{{#a}} {{#b}}...{{/b}} {{/a}}`
    # The regex `\{\{#(\w+)\}\}([\s\S]*?)\{\{/\1\}\}` will match `{{#b}}...{{/b}}` first?
    # Or `{{#a}}...{{/a}}`?
    # It depends on start position.
    # If we have `{{#a}}...{{/a}}`, it matches.
    # Inside it might have `{{#b}}...{{/b}}`.
    # If we process `{{#a}}`, we pass the inner content (including `{{#b}}`) to recursive `view`.
    # So yes, it handles nesting!
    
    result = replace(result, section_regex => (str) -> begin
        m = match(section_regex, str)
        if m === nothing return str end
        
        key = m.captures[1]
        content = m.captures[2]
        
        if haskey(data, key)
            val = data[key]
            if isa(val, AbstractVector)
                # List
                rendered_items = String[]
                for item in val
                    if isa(item, Dict)
                        # Merge with parent data to allow access to parent vars?
                        # For simplicity, just use item + parent data?
                        # Let's just use item for now.
                        # To support parent vars, we'd need `merge(data, item)`.
                        # Let's do `merge(data, item)` but item overwrites.
                        # Note: Dict in Julia is not always string keys.
                        # Assuming Dict{String, Any} or similar.
                        # We need to be careful with types.
                        # Let's just use `item` to avoid type issues for now.
                        push!(rendered_items, render_view(content, item))
                    else
                        # Primitive
                        push!(rendered_items, render_view(content, Dict("." => item)))
                    end
                end
                return join(rendered_items, "")
            elseif isa(val, Bool)
                return val ? render_view(content, data) : ""
            elseif val !== nothing
                # Truthy (e.g. object)
                # If it's a Dict, maybe switch context?
                if isa(val, Dict)
                    return render_view(content, val)
                else
                    return render_view(content, data)
                end
            else
                return ""
            end
        else
            return ""
        end
    end)
    
    # 2. Handle variables {{key}}
    var_regex = r"\{\{([\w\.]+)\}\}"
    
    result = replace(result, var_regex => (str) -> begin
        m = match(var_regex, str)
        if m === nothing return str end
        
        key = m.captures[1]
        
        if key == "." && haskey(data, ".")
            return string(data["."])
        elseif haskey(data, key)
            return string(data[key])
        else
            return ""
        end
    end)
    
    return result
end

"""
    render_view(template::AbstractString; kwargs...) -> String

Renders a template string with the provided keyword arguments.
"""
function render_view(template::AbstractString; kwargs...)
    return render_view(template, Dict{String, Any}(string(k) => v for (k, v) in kwargs))
end

"""
    render_template(file_path::String, data::Dict) -> String

Renders a template file with the provided data.
"""
function render_template(file_path::String, data::Dict)
    if !isfile(file_path)
        throw(ArgumentError("Template file not found: $file_path"))
    end
    
    template = read(file_path, String)
    return render_view(template, data)
end

"""
    render_template(file_path::String; kwargs...) -> String

Renders a template file with the provided keyword arguments.
"""
function render_template(file_path::String; kwargs...)
    return render_template(file_path, Dict{String, Any}(string(k) => v for (k, v) in kwargs))
end

