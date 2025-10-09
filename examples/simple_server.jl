#!/usr/bin/env julia

"""
Simple Nova.jl Server Example

This demonstrates the minimal setup needed to run a Nova.jl application.
Just a basic server that responds "OK" to all requests.
"""

# Add Nova.jl to load path
push!(LOAD_PATH, joinpath(@__DIR__, ".."))

using Nova
using HTTP

# Create a simple handler that just returns "OK"
function simple_handler(req::HTTP.Request)
    return HTTP.Response(200, "OK")
end

println("🚀 Starting simple Nova.jl server on port 2518...")
println("Visit: http://localhost:2518")
println("Press Ctrl+C to stop")

Nova.start_server(simple_handler, port=2518)
