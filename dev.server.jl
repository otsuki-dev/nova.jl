using HTTP
using FileWatching
using Dates

const DEV_PORT = 2518
const WATCH_DIRS = ["pages", "src", "components", "api", "styles", "public"]
const WATCH_EXTENSIONS = [".jl", ".css", ".scss", ".js", ".html", ".svg", ".png", ".jpg"]

function reload_modules()
    try
        Base.include(Main, "src/Nova.jl")
        Base.include(Main, "pages/index.jl")
        @info "✔ Modules reloaded at $(Dates.format(now(), "HH:MM:SS"))"
        return true
    catch e
        @error "✗ Error reloading modules: $e"
        return false
    end
end

function create_handler()
    return function(req)
        try
            static_response = Main.Nova.serve_static(req.target)
            if static_response !== nothing
                return static_response
            end
            
            if req.target == "/"
                return HTTP.Response(200, Main.handler())
            else
                return HTTP.Response(404, """
                <html><body>
                <h1>404 - Page Not Found</h1>
                <p>The page you're looking for doesn't exist.</p>
                <a href="/">← Back to home</a>
                </body></html>
                """)
            end
        catch e
            @error "Request error: $e"
            return HTTP.Response(500, """
            <html><body>
            <h1>500 - Server Error</h1>
            <pre>$e</pre>
            <p><a href="/">← Back to home</a></p>
            </body></html>
            """)
        end
    end
end

function watch_and_reload()
    @async begin
        file_times = Dict{String, Float64}()
        
        function scan_for_changes()
            for dir in WATCH_DIRS
                if isdir(dir)
                    for file in readdir(dir, join=true)
                        if isfile(file) && any(endswith(file, ext) for ext in WATCH_EXTENSIONS)
                            try
                                mtime = stat(file).mtime
                                if !haskey(file_times, file) || file_times[file] < mtime
                                    if haskey(file_times, file)
                                        @info "File changed: $(basename(file))"
                                        sleep(0.2)
                                        reload_modules()
                                    end
                                    file_times[file] = mtime
                                end
                            catch e
                            end
                        end
                    end
                end
            end
        end
        
        while true
            try
                scan_for_changes()
                sleep(1)
            catch e
                @warn "File monitoring error: $e"
                sleep(5)
            end
        end
    end
end

function main()
    println("Nova.jl Development Server")
    println("=" ^ 50)
    
    if !reload_modules()
        @error "Failed to load initial modules"
        return
    end
    
    watch_and_reload()
    
    @info "☻ Server starting at http://localhost:$DEV_PORT"
    @info "ⓘ Watching: $(join(WATCH_DIRS, ", "))"
    @info "♻ Hot reload active - save .jl files to see changes!"
    @info "Press Ctrl+C to stop"
    
    try
        HTTP.serve(create_handler(), "127.0.0.1", DEV_PORT)
    catch e
        if isa(e, InterruptException)
            @info "☺ Server stopped"
        else
            @error "Server error: $e"
        end
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
