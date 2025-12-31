"""
    Server.Router

Module for handling routing logic and file-based routing system.
"""

# Cache for compiled page modules
# Map: file_path => (mtime, module_instance)
const PAGE_CACHE = Dict{String, Tuple{Float64, Module}}()

# Static routes for AOT/Production
# Map: url_path => handler_function
const STATIC_ROUTES = Ref{Union{Dict{String, Function}, Nothing}}(nothing)

"""
    register_static_routes(routes::Dict{String, Function})

Registers a static route map for production use.
If registered, these routes take precedence over file system scanning.
"""
function register_static_routes(routes::Dict{String, Function})
    STATIC_ROUTES[] = routes
end

"""
    match_static_route(path::String) -> Tuple{Union{Function, Nothing}, Dict{String, String}}

Matches a path against registered static routes.
Returns (handler_function, params).
"""
function match_static_route(path::String)
    routes = STATIC_ROUTES[]
    if routes === nothing
        return nothing, Dict{String,String}()
    end
    
    # 1. Exact match
    if haskey(routes, path)
        return routes[path], Dict{String,String}()
    end
    
    # 2. Pattern match
    clean_path = strip(path, '/')
    segments = isempty(clean_path) ? String[] : split(clean_path, '/')
    
    for (route_pattern, handler) in routes
        # Skip exact matches (already checked)
        if !contains(route_pattern, "[") continue end
        
        pat_clean = strip(route_pattern, '/')
        pat_segments = isempty(pat_clean) ? String[] : split(pat_clean, '/')
        
        if length(segments) != length(pat_segments) continue end
        
        match = true
        params = Dict{String,String}()
        
        for i in 1:length(segments)
            if startswith(pat_segments[i], "[") && endswith(pat_segments[i], "]")
                key = pat_segments[i][2:end-1]
                params[key] = segments[i]
            elseif segments[i] != pat_segments[i]
                match = false
                break
            end
        end
        
        if match
            return handler, params
        end
    end
    
    return nothing, Dict{String,String}()
end

"""
    clear_page_cache()

Clears the page module cache. Call this when page files change.
"""
function clear_page_cache()
    empty!(PAGE_CACHE)
end

# Already exported by Nova.jl

"""
    scan_routes(pages_dir::String="pages", api_dir::String="api") -> Dict{String, String}

Scans the pages and api directories and generates a route map.
Returns a dictionary mapping URL paths to file paths.

# Examples
```julia
routes = scan_routes("pages", "api")
# Dict("/", "pages/index.jl", "/api/users" => "api/users.jl", ...)
```
"""
function scan_routes(pages_dir::String="pages", api_dir::String="api")
    route_map = Dict{String, String}()
    
    # Helper to scan a directory
    function scan_directory(dir::String, base_path::String="")
        if !isdir(dir) return end
        
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
    
    # Scan pages directory (mapped to root)
    if isdir(pages_dir)
        scan_directory(pages_dir, "")
    else
        @warn "Pages directory not found: $pages_dir"
    end
    
    # Scan api directory (mapped to /api)
    if isdir(api_dir)
        scan_directory(api_dir, "/api")
    end
    
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
        # We wrap the handler to pass req and params
        print(io, "    \"$route_path\" => (req, params) -> $module_name.handler(req, params)")
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
    match_route(path::String, pages_dir::String="pages", api_dir::String="api") -> Tuple{Union{String, Nothing}, Dict{String, String}}

Matches a URL path to a file path, extracting dynamic parameters.
Returns a tuple of (file_path, params).

# Examples
```julia
file, params = match_route("/users/123")
# ("pages/users/[id].jl", Dict("id" => "123"))
```
"""
function match_route(path::String, pages_dir::String="pages", api_dir::String="api")
    clean_path = strip(path, '/')
    segments = isempty(clean_path) ? String[] : split(clean_path, '/')
    
    # Check for API route
    if (startswith(clean_path, "api/") || clean_path == "api") && isdir(api_dir)
        api_segments = clean_path == "api" ? String[] : segments[2:end]
        file, params = find_fs_match(api_segments, api_dir)
        if file !== nothing
            return file, params
        end
    end
    
    # Check for Page route
    return find_fs_match(segments, pages_dir)
end

function find_fs_match(segments::Vector{SubString{String}}, current_dir::String)
    return find_fs_match(String.(segments), current_dir)
end

function find_fs_match(segments::Vector{String}, current_dir::String)
    if !isdir(current_dir)
        return nothing, Dict{String,String}()
    end

    if isempty(segments)
        # Look for index.jl
        index_file = joinpath(current_dir, "index.jl")
        if isfile(index_file)
            return index_file, Dict{String,String}()
        end
        return nothing, Dict{String,String}()
    end

    segment = segments[1]
    remaining = segments[2:end]
    
    # 1. Exact Match
    
    # File: segment.jl (only if last segment)
    if isempty(remaining)
        file_path = joinpath(current_dir, segment * ".jl")
        if isfile(file_path)
            return file_path, Dict{String,String}()
        end
    end
    
    # Directory: segment/
    dir_path = joinpath(current_dir, segment)
    if isdir(dir_path)
        file, params = find_fs_match(remaining, dir_path)
        if file !== nothing
            return file, params
        end
    end
    
    # 2. Dynamic Match ([param])
    
    entries = readdir(current_dir)
    
    # File: [param].jl (only if last segment)
    if isempty(remaining)
        for entry in entries
            if startswith(entry, "[") && endswith(entry, "].jl")
                param_name = entry[2:end-4]
                return joinpath(current_dir, entry), Dict(param_name => segment)
            end
        end
    end
    
    # Directory: [param]/
    for entry in entries
        full_path = joinpath(current_dir, entry)
        if isdir(full_path) && startswith(entry, "[") && endswith(entry, "]")
            param_name = entry[2:end-1]
            file, params = find_fs_match(remaining, full_path)
            if file !== nothing
                params[param_name] = segment
                return file, params
            end
        end
    end
    
    return nothing, Dict{String,String}()
end

"""
    route_to_file(path::String, pages_dir::String="pages", api_dir::String="api") -> Union{String, Nothing}

Converts a URL path to a file path in the pages or api directory.
Returns the file path if it exists, nothing otherwise.

# Examples
```julia
route_to_file("/")              # Returns "pages/index.jl"
route_to_file("/about")         # Returns "pages/about.jl"
route_to_file("/api/users")     # Returns "api/users.jl"
```
"""
function route_to_file(path::String, pages_dir::String="pages", api_dir::String="api")
    file, _ = match_route(path, pages_dir, api_dir)
    return file
end

"""
    handle_page_route(file_path::String, params::Dict{String,String}=Dict{String,String}(), req::HTTP.Request=HTTP.Request("GET", "/")) -> Union{String, HTTP.Response, Nothing}

Loads and executes a page file, returning the rendered HTML or HTTP.Response.
Uses a cache to avoid recompiling unchanged files.

# Examples
```julia
html = handle_page_route("pages/index.jl")
```
"""
function handle_page_route(file_path::String, params::Dict{String,String}=Dict{String,String}(), req::HTTP.Request=HTTP.Request("GET", "/"))
    if !isfile(file_path)
        return nothing
    end
    
    try
        current_mtime = mtime(file_path)
        
        # Check cache
        if haskey(PAGE_CACHE, file_path)
            cached_mtime, cached_mod = PAGE_CACHE[file_path]
            if current_mtime == cached_mtime
                # Cache hit
                return execute_handler(cached_mod, req, params)
            end
        end
        
        # Cache miss or stale - Compile
        # Create a unique module name based on file path
        mod_name = Symbol("Page_" * replace(file_path, r"[^a-zA-Z0-9]" => "_"))
        
        # Create a new module for this page
        # We evaluate it in Main to ensure it can load packages easily, 
        # but we keep it isolated as a named module
        mod = Module(mod_name)
        
        # Make Nova available in the module
        # We assume Nova is available in the parent scope
        Core.eval(mod, :(using Nova))
        Core.eval(mod, :(using HTTP))
        
        # Include the file content into the module
        Base.include(mod, file_path)
        
        # Update cache
        PAGE_CACHE[file_path] = (current_mtime, mod)
        
        return execute_handler(mod, req, params)
        
    catch e
        @error "Error loading page $file_path: $e"
        bt = catch_backtrace()
        @error "Stacktrace:" exception=(e, bt)
        return nothing
    end
end

function execute_handler(mod::Module, req::HTTP.Request, params::Dict{String,String})
    if isdefined(mod, :handler)
        try
            return Base.invokelatest(mod.handler, req, params)
        catch e
            if e isa MethodError
                try
                    return Base.invokelatest(mod.handler, params)
                catch e2
                    if e2 isa MethodError
                        return Base.invokelatest(mod.handler)
                    else
                        rethrow(e2)
                    end
                end
            else
                rethrow(e)
            end
        end
    else
        @warn "Page module $(nameof(mod)) does not define a handler() function"
        return nothing
    end
end
