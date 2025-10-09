"""
    Utils.FileSystem

Utility module for file system operations.
"""

export find_files, read_file_safe

"""
    find_files(dir::String, extensions::Vector{String}) -> Vector{String}

Recursively finds all files in a directory with the given extensions.

# Examples
```julia
find_files("styles", [".css", ".scss"])
```
"""
function find_files(dir::String, extensions::Vector{String})
    files = String[]
    
    if !isdir(dir)
        return files
    end
    
    for item in readdir(dir, join=true)
        if isfile(item) && any(endswith(item, ext) for ext in extensions)
            push!(files, item)
        elseif isdir(item)
            append!(files, find_files(item, extensions))
        end
    end
    
    return files
end

"""
    read_file_safe(path::String) -> Union{String, Nothing}

Safely reads a file and returns its content, or nothing if an error occurs.
"""
function read_file_safe(path::String)
    try
        return read(path, String)
    catch e
        @warn "Failed to read file $path: $e"
        return nothing
    end
end
