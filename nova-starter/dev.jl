#!/usr/bin/env julia

"""
Nova.jl Basic Example - Development Server

This is an example application showing how to use Nova.jl framework.
Run this file to start the development server with hot reload enabled.

Usage:
    julia examples/basic/dev.jl
"""

using Nova

println("=" ^ 60)
println("Nova.jl - Basic Example")
println("=" ^ 60)

# Initial module load
println("📦 Loading modules...")
# Pre-load index to ensure it works
if isfile(joinpath(@__DIR__, "src", "pages", "index.jl"))
    include(joinpath(@__DIR__, "src", "pages", "index.jl"))
end

# Start hot reload watcher
println("🔄 Starting hot reload...")
Nova.watch_and_reload(
    dirs=[
        joinpath(@__DIR__, "src", "pages"), 
        joinpath(@__DIR__, "src", "components"), 
        joinpath(@__DIR__, "src", "styles")
    ],
    extensions=[".jl", ".css", ".scss"],
    modules=[] # Nova reloads automatically, explicit modules list is optional/legacy
)

# Create handler with correct directories
server_handler = Nova.create_handler(
    pages_dir=joinpath(@__DIR__, "src", "pages"),
    public_dir=joinpath(@__DIR__, "public"),
    api_dir=joinpath(@__DIR__, "src", "pages", "api") # Next.js style: api inside pages
)

# Start server
println("\n🚀 Starting development server...")
Nova.start_server(server_handler, port=2518)
