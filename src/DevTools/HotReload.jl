"""
    DevTools.HotReload

Module for hot reloading functionality during development.
Watches files for changes and triggers automatic reloads.
"""

# Already exported by Nova.jl
# Uses FileWatching and Dates (imported in Nova.jl)

"""
    reload_modules(modules::Vector{String}) -> Bool

Reloads the specified module files.
Returns true if successful, false otherwise.

# Examples
```julia
reload_modules(["src/Nova.jl", "pages/index.jl"])
```
"""
function reload_modules(modules::Vector{String}=["src/Nova.jl"])
    try
        # Clear caches
        if isdefined(Main.Nova, :clear_style_cache)
            Main.Nova.clear_style_cache()
        end
        if isdefined(Main.Nova, :clear_page_cache)
            Main.Nova.clear_page_cache()
        end

        for module_path in modules
            if isfile(module_path)
                Base.include(Main, module_path)
            end
        end
        timestamp = Dates.format(now(), "HH:MM:SS")
        printstyled("  ✓  ", color=:green, bold=true)
        printstyled("Modules reloaded", color=:light_black)
        printstyled(" [$timestamp]", color=:light_black)
        println()
        return true
    catch e
        printstyled("  ✗  ", color=:red, bold=true)
        printstyled("Error reloading modules: ", color=:light_black)
        printstyled("$e", color=:red)
        println()
        return false
    end
end

"""
    watch_and_reload(; dirs::Union{Vector{String},Nothing}=nothing, 
                      extensions::Vector{String}=[".jl", ".css", ".scss"],
                      modules::Vector{String}=["src/Nova.jl"],
                      interval::Float64=1.0)

Watches specified directories for file changes and triggers module reloads.
Runs asynchronously in the background.
Uses smart defaults for directories if not provided.

# Arguments
- `dirs`: Directories to watch. Defaults to ["src/pages", "src/components", "src/styles"] if they exist, otherwise legacy paths.
- `extensions`: File extensions to watch.
- `modules`: Module files to reload.
- `interval`: Check interval in seconds.
"""
function watch_and_reload(; 
                         dirs::Union{Vector{String},Nothing}=nothing,
                         extensions::Vector{String}=[".jl", ".css", ".scss"],
                         modules::Vector{String}=["src/Nova.jl"],
                         interval::Float64=1.0)
    
    # Smart defaults for dirs
    if dirs === nothing
        dirs = String[]
        # Check for modern structure
        if isdir(joinpath("src", "pages")) push!(dirs, joinpath("src", "pages")) end
        if isdir(joinpath("src", "components")) push!(dirs, joinpath("src", "components")) end
        if isdir(joinpath("src", "styles")) push!(dirs, joinpath("src", "styles")) end
        
        # Fallback to legacy structure if modern not found
        if isempty(dirs)
            push!(dirs, "pages")
            push!(dirs, "src")
            push!(dirs, "components")
            push!(dirs, "styles")
        end
    end

    @async begin
        file_times = Dict{String, Float64}()
        
        function scan_for_changes()
            for dir in dirs
                if !isdir(dir)
                    continue
                end
                
                for file in readdir(dir, join=true)
                    if isfile(file) && any(endswith(file, ext) for ext in extensions)
                        try
                            mtime = stat(file).mtime
                            if !haskey(file_times, file) || file_times[file] < mtime
                                if haskey(file_times, file)
                                    printstyled("  ▫  ", color=:cyan, bold=true)
                                    printstyled("File changed: ", color=:light_black)
                                    printstyled(basename(file), color=:cyan)
                                    println()
                                    sleep(0.2)  # Debounce
                                    reload_modules(modules)
                                end
                                file_times[file] = mtime
                            end
                        catch e
                            @warn "Error checking file $file: $e"
                        end
                    end
                end
            end
        end
        
        printstyled("  ℹ  ", color=:blue, bold=true)
        printstyled("Hot reload active - watching: ", color=:light_black)
        printstyled(join(dirs, ", "), color=:white)
        println()
        
        while true
            try
                scan_for_changes()
                sleep(interval)
            catch e
                printstyled("  ⚠  ", color=:yellow, bold=true)
                printstyled("File monitoring error: ", color=:light_black)
                printstyled("$e", color=:yellow)
                println()
                sleep(5)
            end
        end
    end
end
