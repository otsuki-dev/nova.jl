"""
    Server.Router

Module for handling routing logic and file-based routing system.
"""

# Already exported by Nova.jl

"""
    scan_routes(pages_dir::String="pages") -> Dict{String, String}

Scans the pages directory and generates a route map.
Returns a dictionary mapping URL paths to file paths.

# Examples
```julia
routes = scan_routes("pages")
# Dict("/", "pages/index.jl", "/about" => "pages/about.jl", ...)
```
"""
function scan_routes(pages_dir::String="pages")
    route_map = Dict{String, String}()
    
    if !isdir(pages_dir)
        @warn "Pages directory not found: $pages_dir"
        return route_map
    end
    
    # Recursively scan for .jl files
    function scan_directory(dir::String, base_path::String="")
        for item in readdir(dir, join=false)
            full_path = joinpath(dir, item)
            
            if isfile(full_path) && endswith(item, ".jl")
                # Generate URL path
                if item == "index.jl"
                    url_path = base_path == "" ? "/" : base_path
                else
                    filename = replace(item, ".jl" => "")
                    url_path = base_path == "" ? "/$filename" : "$base_path/$filename"
                end
                
                route_map[url_path] = full_path
            elseif isdir(full_path)
                # Recursively scan subdirectories
                new_base = base_path == "" ? "/$item" : "$base_path/$item"
                scan_directory(full_path, new_base)
            end
        end
    end
    
    scan_directory(pages_dir)
    return route_map
end

"""
    generate_route_file(route_map::Dict{String, String}, output_file::String="build/routes_generated.jl")

Generates a Julia file with precompiled route handlers.
This file can be used with PackageCompiler for AOT compilation.

# Examples
```julia
routes = scan_routes("pages")
generate_route_file(routes, "build/routes_generated.jl")
```
"""
function generate_route_file(route_map::Dict{String, String}, output_file::String="build/routes_generated.jl")
    # Create build directory if needed
    output_dir = dirname(output_file)
    if !isdir(output_dir)
        mkpath(output_dir)
    end
    
    # Generate the routes file
    io = IOBuffer()
    
    println(io, "# Auto-generated route handlers for AOT compilation")
    println(io, "# Generated at: ", now())
    println(io, "")
    println(io, "module GeneratedRoutes")
    println(io, "")
    println(io, "using HTTP")
    println(io, "")
    
    # Generate handler modules for each route
    for (route_path, file_path) in sort(collect(route_map))
        # Create a unique module name
        module_name = replace(replace(route_path, "/" => "_"), "-" => "_")
        module_name = "Route" * (module_name == "_" ? "_root" : module_name)
        
        println(io, "module $module_name")
        println(io, "    include(\"$(abspath(file_path))\")")
        println(io, "end")
        println(io, "")
    end
    
    # Generate route map
    println(io, "# Route map: URL => handler module")
    println(io, "const ROUTE_HANDLERS = Dict{String, Function}(")
    
    first = true
    for (route_path, _) in sort(collect(route_map))
        module_name = replace(replace(route_path, "/" => "_"), "-" => "_")
        module_name = "Route" * (module_name == "_" ? "_root" : module_name)
        
        if !first
            println(io, ",")
        end
        print(io, "    \"$route_path\" => () -> $module_name.handler()")
        first = false
    end
    
    println(io, "")
    println(io, ")")
    println(io, "")
    println(io, "end # module GeneratedRoutes")
    
    # Write to file
    write(output_file, String(take!(io)))
    
    return output_file
end

"""
    route_to_file(path::String, pages_dir::String="pages") -> Union{String, Nothing}

Converts a URL path to a file path in the pages directory.
Returns the file path if it exists, nothing otherwise.

# Examples
```julia
route_to_file("/")              # Returns "pages/index.jl"
route_to_file("/about")         # Returns "pages/about.jl"
route_to_file("/docs/guide")    # Returns "pages/docs/guide.jl"
```
"""
function route_to_file(path::String, pages_dir::String="pages")
    # Remove leading/trailing slashes
    clean_path = strip(path, '/')
    
    # Root path maps to index.jl
    if isempty(clean_path) || clean_path == "/"
        file_path = joinpath(pages_dir, "index.jl")
        return isfile(file_path) ? file_path : nothing
    end
    
    # Try direct mapping
    file_path = joinpath(pages_dir, clean_path * ".jl")
    if isfile(file_path)
        return file_path
    end
    
    # Try as directory with index.jl
    dir_index = joinpath(pages_dir, clean_path, "index.jl")
    if isfile(dir_index)
        return dir_index
    end
    
    return nothing
end

"""
    handle_page_route(file_path::String) -> Union{String, HTTP.Response, Nothing}

Loads and executes a page file, returning the rendered HTML or HTTP.Response.
The page file should define a `handler()` function.

# Examples
```julia
html = handle_page_route("pages/index.jl")
```
"""
function handle_page_route(file_path::String)
    if !isfile(file_path)
        return nothing
    end
    
    try
        # Include the page file in Main module
        Base.include(Main, file_path)
        
        # Call the handler function
        if isdefined(Main, :handler)
            result = Main.handler()
            # Handler can return either String (HTML) or HTTP.Response (for APIs)
            return result
        else
            @warn "Page $file_path does not define a handler() function"
            return nothing
        end
    catch e
        @error "Error loading page $file_path: $e"
        bt = catch_backtrace()
        @error "Stacktrace:" exception=(e, bt)
        return nothing
    end
end
