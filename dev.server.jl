using HTTP
using WebSockets
using JSON
include("src/chess_server.jl")
using .ChessServer
using FileWatching
using Dates

const DEV_PORT = 2518
const WATCH_DIRS = ["src/pages", "src", "components", "api", "styles", "public"]
const WATCH_EXTENSIONS = [".jl", ".css", ".scss", ".js", ".html", ".svg", ".png", ".jpg"]

function reload_modules()
    try
        Base.include(Main, "src/Nova.jl")
        Base.include(Main, "src/pages/index.jl")
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
            # HTTP API fallback for chess (join, move, state)
            if startswith(req.target, "/api/chess")
                try
                    method = String(req.method)
                    if req.target == "/api/chess/join" && method == "POST"
                        body = String(take!(req.body))
                        obj = JSON.parse(body)
                        state = ChessServer.create_game(get(obj, "mode", "human"))
                        return HTTP.Response(200, JSON.json(Dict("type"=>"state","id"=>state[:id],"board"=>state[:board],"turn"=>state[:turn])))
                    elseif req.target == "/api/chess/move" && method == "POST"
                        body = String(take!(req.body))
                        obj = JSON.parse(body)
                        id = obj["id"]
                        ok, reason = ChessServer.handle_move(id, obj["from"], obj["to"])
                        s = ChessServer.get_state(id)
                        # if ai mode and it's ai turn
                        if s !== nothing && s[:mode] == "ai" && s[:turn] == "black"
                            ChessServer.ai_move!(s)
                        end
                        s2 = ChessServer.get_state(id)
                        return HTTP.Response(200, JSON.json(Dict("type"=>"move_result","ok"=>ok,"reason"=>reason,"state"=> (s2 === nothing ? nothing : s2[:board]))))
                    elseif startswith(req.target, "/api/chess/state") && method == "GET"
                        q = HTTP.URIs.queryparams(req.target)
                        id = get(q, "id", nothing)
                        s = ChessServer.get_state(id)
                        if s === nothing
                            return HTTP.Response(404, "{}")
                        end
                        return HTTP.Response(200, JSON.json(Dict("type"=>"state","id"=>s[:id],"board"=>s[:board],"turn"=>s[:turn])))
                    else
                        return HTTP.Response(404, "{}")
                    end
                catch e
                    @error "API chess error: $e"
                    return HTTP.Response(500, "{}")
                end
            end

            # WebSocket endpoint for chess
            if req.target == "/ws/chess"
                return WebSockets.upgrade(req) do ws
                    # simple text-based JSON protocol
                    try
                        # Expect first message to be join -> {"type":"join","mode":"ai"|"human"}
                        msg = WebSockets.read(ws)
                        obj = JSON.parse(msg)
                        state = ChessServer.create_game(get(obj, "mode", "human"))
                        # send initial state
                        WebSockets.send(ws, JSON.json(Dict("type"=>"state","id"=>state[:id],"board"=>state[:board],"turn"=>state[:turn])))
                        while true
                            msg = WebSockets.read(ws)
                            obj = JSON.parse(msg)
                            if obj["type"] == "move"
                                ok, reason = ChessServer.handle_move(state[:id], obj["from"], obj["to"])
                                WebSockets.send(ws, JSON.json(Dict("type"=>"move_result","ok"=>ok,"reason"=>reason)))
                                # send updated state
                                s = ChessServer.get_state(state[:id])
                                WebSockets.send(ws, JSON.json(Dict("type"=>"state","board"=>s[:board],"turn"=>s[:turn])))
                                # if AI mode and it's AI turn, make AI move
                                if state[:mode] == "ai" && s[:turn] == "black"
                                    ChessServer.ai_move!(s)
                                    WebSockets.send(ws, JSON.json(Dict("type"=>"state","board"=>s[:board],"turn"=>s[:turn])))
                                end
                            end
                        end
                    catch e
                        @warn "WebSocket error: $e"
                    end
                end
            elseif req.target == "/templates"
                try
                    Base.include(Main, "pages/templates.jl")
                    return HTTP.Response(200, Main.handler())
                catch e
                    @error "Error loading templates page: $e"
                    return HTTP.Response(500, "Error loading templates page")
                end
            elseif req.target == "/documentation"
                try
                    Base.include(Main, "pages/documentation.jl")
                    return HTTP.Response(200, Main.handler())
                catch e
                    @error "Error loading documentation page: $e"
                    return HTTP.Response(500, "Error loading documentation page")
                end
            elseif req.target == "/"
                return HTTP.Response(200, Main.handler())
            else
                return HTTP.Response(404, """
                <html><body>
                <h1>404 - Page Not Found</h1>
                <p>The page you're looking for doesn't exist.</p>
                <a href="/">Back to home</a>
                </body></html>
                """)
            end
        catch e
            @error "Request error: $e"
            return HTTP.Response(500, """
            <html><body>
            <h1>500 - Server Error</h1>
            <pre>$e</pre>
            <p><a href="/">Back to home</a></p>
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
