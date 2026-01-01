#!/usr/bin/env julia

using Nova

println("🚀 Starting Nova.jl development server...")

# Start hot reload watcher
# We watch the src directory for changes
Nova.watch_and_reload(
    dirs=["src/pages", "src/components", "src/styles"],
    extensions=[".jl", ".css", ".scss"]
)

# Create handler (auto-detects src/pages)
handler = Nova.create_handler()

Nova.start_server(handler)
