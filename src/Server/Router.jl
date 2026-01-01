"""
    Server.Router

Module for handling routing logic and file-based routing system.
"""

# Cache for compiled page modules
# Map: file_path => (mtime, module_instance)
const PAGE_CACHE = Dict{String, Tuple{Float64, Module}}()

# Trie Node Structure for Optimized Routing
mutable struct TrieNode
    part::String
    children::Dict{String, TrieNode}
    is_param::Bool
    param_name::String
    handler::Union{Function, Nothing}
end

TrieNode(part::AbstractString) = TrieNode(String(part), Dict{String, TrieNode}(), false, "", nothing)

# Root of the routing trie
const ROUTE_TRIE = Ref{TrieNode}(TrieNode(""))

const EMPTY_PARAMS = Dict{String,String}()

"""
    register_static_routes(routes::Dict{String, Function})

Registers a static route map for production use.
Builds a Radix Tree (Trie) for O(k) matching where k is the number of segments.
"""
function register_static_routes(routes::Dict{String, Function})
    root = TrieNode("")
    
    for (path, handler) in routes
        clean_path = strip(path, '/')
        segments = isempty(clean_path) ? String[] : split(clean_path, '/')
        
        current = root
        
        for segment in segments
            is_param = startswith(segment, "[") && endswith(segment, "]")
            key = is_param ? ":param" : segment
            
            if !haskey(current.children, key)
                node = TrieNode(key)
                if is_param
                    node.is_param = true
                    node.param_name = segment[2:end-1]
                end
                current.children[key] = node
            end
            
            current = current.children[key]
        end
        
        current.handler = handler
    end
    
    ROUTE_TRIE[] = root
end

"""
    match_static_route(path::String) -> Tuple{Union{Function, Nothing}, Dict{String, String}}

Matches a path against registered static routes using the Trie.
Returns (handler_function, params).
"""
function match_static_route(path::String)
    root = ROUTE_TRIE[]
    
    # Optimization: Handle root path
    if path == "/" || path == ""
        return root.handler, EMPTY_PARAMS
    end
    
    current = root
    params = Dict{String,String}()
    
    # Iterate over path segments without splitting
    # We find the start and end indices of each segment
    start_idx = 1
    if startswith(path, '/')
        start_idx = 2
    end
    
    len = length(path)
    while start_idx <= len
        # Find next slash
        end_idx = findnext(==('/'), path, start_idx)
        if end_idx === nothing
            end_idx = len + 1
        end
        
        # Extract segment
        # Using SubString to avoid allocation
        segment = SubString(path, start_idx, end_idx-1)
        
        # 1. Try exact match
        if haskey(current.children, segment)
            current = current.children[segment]
        # 2. Try param match
        elseif haskey(current.children, ":param")
            current = current.children[":param"]
            params[current.param_name] = segment
        else
            return nothing, EMPTY_PARAMS
        end
        
        start_idx = end_idx + 1
    end
    
    return current.handler, params
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
    scan_routes(pages_dir::Union{String,Nothing}=nothing, api_dir::Union{String,Nothing}=nothing) -> Dict{String, String}

Scans the pages and api directories and generates a route map.
Returns a dictionary mapping URL paths to file paths.
Uses smart defaults if directories are not provided.

# Examples
```julia
routes = scan_routes()
routes = scan_routes("src/pages", "src/pages/api")
```
"""
function scan_routes(pages_dir::Union{String,Nothing}=nothing, api_dir::Union{String,Nothing}=nothing)
    # Smart defaults (logic duplicated from Server.jl for consistency)
    if pages_dir === nothing
        if isdir(joinpath("src", "pages"))
            pages_dir = joinpath("src", "pages")
        else
            pages_dir = "pages"
        end
    end

    if api_dir === nothing
        if pages_dir == joinpath("src", "pages") && isdir(joinpath("src", "pages", "api"))
            api_dir = joinpath("src", "pages", "api")
        elseif isdir("api")
            api_dir = "api"
        else
            possible_api = joinpath(pages_dir, "api")
            api_dir = isdir(possible_api) ? possible_api : "api"
        end
    end

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
    println(io, "using Nova")
    println(io, "")
    
    # Generate handler modules for each route
    for (route_path, file_path) in sort(collect(route_map))
        # Create a unique module name
        # Replace invalid characters for module names
        safe_path = replace(route_path, r"[^a-zA-Z0-9_]" => "_")
        module_name = "Route" * (safe_path == "_" ? "_root" : safe_path)
        
        println(io, "module $module_name")
        println(io, "    using Nova")
        println(io, "    using HTTP")
        println(io, "    include(\"$(abspath(file_path))\")")
        println(io, "end")
        println(io, "")
    end
    
    # Generate route map
    println(io, "# Route map: URL => handler module")
    println(io, "const ROUTE_HANDLERS = Dict{String, Function}(")
    
    first = true
    for (route_path, _) in sort(collect(route_map))
        safe_path = replace(route_path, r"[^a-zA-Z0-9_]" => "_")
        module_name = "Route" * (safe_path == "_" ? "_root" : safe_path)
        
        if !first
            println(io, ",")
        end
        # We wrap the handler to pass req and params with dispatch logic
        print(io, """    "$route_path" => (req, params) -> begin
        h = $module_name.handler
        if applicable(h, req, params)
            h(req, params)
        elseif applicable(h, params)
            h(params)
        else
            h()
        end
    end""")
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
        
        # Define include to work within the module
        Core.eval(mod, :(function include(path)
            Base.include(@__MODULE__, path)
        end))
        
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
    # Use invokelatest to check for handler existence and get it
    # This avoids world age issues with isdefined and getfield
    get_h(m) = isdefined(m, :handler) ? m.handler : nothing
    
    handler_func = Base.invokelatest(get_h, mod)
    
    if handler_func !== nothing
        try
            return Base.invokelatest(handler_func, req, params)
        catch e
            if e isa MethodError
                try
                    return Base.invokelatest(handler_func, params)
                catch e2
                    if e2 isa MethodError
                        return Base.invokelatest(handler_func)
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
