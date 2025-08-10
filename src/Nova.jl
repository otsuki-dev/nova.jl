module Nova

using HTTP

greet() = print("Welcome to Nova.jl!")

export render, auto_load_styles, serve_static, process_scss, get_mime_type, auto_favicon

function auto_load_styles()
    styles_content = ""
    styles_dir = "styles"
    
    if isdir(styles_dir)
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
                    @warn "Erro ao carregar estilo $file: $e"
                end
            end
        end
    end
    
    return """<style>\n$styles_content\n</style>"""
end

function process_scss(scss_content::String)
    css_content = scss_content
        css_content = replace(css_content, r"//.*$"m => "")
    
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
    
    for (var, value) in variables
        css_content = replace(css_content, var => value)
    end
    
    css_content = replace(css_content, r"^\s*\$.*$"m => "")
    
    return css_content
end

function serve_static(request_path::String)
    clean_path = lstrip(request_path, '/')
    
    public_file = joinpath("public", clean_path)
    
    if isfile(public_file)
        try
            mime_type = get_mime_type(public_file)
            
            if startswith(mime_type, "image/") || mime_type == "application/octet-stream"
                content = read(public_file)
                return HTTP.Response(200, ["Content-Type" => mime_type], content)
            else
                content = read(public_file, String)
                return HTTP.Response(200, ["Content-Type" => mime_type], content)
            end
        catch e
            @warn "Erro ao servir arquivo $public_file: $e"
        end
    end
    
    return nothing
end

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
        "txt" => "text/plain"
    )
    
    return get(mime_types, ext, "application/octet-stream")
end

function auto_favicon()
    favicon_files = [
        ("favicon.svg", "image/svg+xml"),
        ("favicon.ico", "image/x-icon"),
        ("favicon.png", "image/png"),
        ("icon.svg", "image/svg+xml"),
        ("icon.ico", "image/x-icon"),
        ("icon.png", "image/png")
    ]
    
    for (filename, mime_type) in favicon_files
        if isfile(joinpath("public", filename))
            return """<link rel="icon" type="$mime_type" href="/$filename">"""
        end
    end
    
    return ""
end

function render(content::String; auto_styles::Bool = true)
    styles_html = auto_styles ? auto_load_styles() : ""
    favicon_html = auto_favicon()
    
    return """
    <!DOCTYPE html>
    <html lang="pt-BR">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        $favicon_html
        <title>Nova.jl App</title>
        $styles_html
      </head>
      <body>
        $content
      </body>
    </html>
    """
end

end
