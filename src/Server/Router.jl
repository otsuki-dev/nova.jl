"""
    Server.Router

Module for handling routing logic and file-based routing system.
"""

# Already exported by Nova.jl

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
