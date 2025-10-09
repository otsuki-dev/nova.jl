#!/usr/bin/env julia

"""
Nova.jl Basic Example - Development Server

This is an example application showing how to use Nova.jl framework.
Run this file to start the development server with hot reload enabled.

Usage:
    julia examples/basic/dev.jl
"""

# Add parent directory to load path to use local Nova.jl
push!(LOAD_PATH, joinpath(@__DIR__, "..", ".."))

using Nova

println("=" ^ 60)
println("Nova.jl - Basic Example")
println("=" ^ 60)

# Initial module load
println("📦 Loading modules...")
include("pages/index.jl")

# Start hot reload watcher
println("🔄 Starting hot reload...")
Nova.watch_and_reload(
    dirs=["examples/basic/pages", "examples/basic/components", "examples/basic/styles"],
    extensions=[".jl", ".css", ".scss"],
    modules=["examples/basic/pages/index.jl"]
)

# Create handler with example directories
handler = Nova.create_handler(
    pages_dir="examples/basic/pages",
    public_dir="examples/basic/public"
)

# Start server
println("\n🚀 Starting development server...")
Nova.start_server(handler, port=2518)
