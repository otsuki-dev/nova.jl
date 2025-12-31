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
    watch_and_reload(; dirs::Vector{String}=["pages", "src", "components", "styles"], 
                      extensions::Vector{String}=[".jl", ".css", ".scss"],
                      modules::Vector{String}=["src/Nova.jl"],
                      interval::Float64=1.0)

Watches specified directories for file changes and triggers module reloads.
Runs asynchronously in the background.

# Arguments
- `dirs::Vector{String}`: Directories to watch (default: ["pages", "src", "components", "styles"])
- `extensions::Vector{String}`: File extensions to watch (default: [".jl", ".css", ".scss"])
- `modules::Vector{String}`: Module files to reload on change (default: ["src/Nova.jl"])
- `interval::Float64`: Check interval in seconds (default: 1.0)

# Examples
```julia
# Watch with defaults
watch_and_reload()

# Custom configuration
watch_and_reload(
    dirs=["src", "pages"], 
    extensions=[".jl"], 
    interval=0.5
)
```
"""
function watch_and_reload(; 
                         dirs::Vector{String}=["pages", "src", "components", "styles"],
                         extensions::Vector{String}=[".jl", ".css", ".scss"],
                         modules::Vector{String}=["src/Nova.jl"],
                         interval::Float64=1.0)
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
