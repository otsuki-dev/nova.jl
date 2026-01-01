#!/usr/bin/env julia

"""
Nova.jl Precompilation Script

This script exercises the Nova.jl framework to generate precompilation data
for PackageCompiler.jl. It simulates typical usage patterns to "warm up" the JIT
compiler and cache compiled code in the sysimage.
"""

println("📦 Precompiling Nova.jl framework...")

# Activate project environment
using Pkg
Pkg.activate(".")

# Load the framework
include("src/Nova.jl")
using .Nova

# Import dependencies to precompile
using HTTP
using JSON

println("  ✓ Framework loaded")

# Exercise routing functions
println("  → Testing routing...")
Nova.route_to_file("/")
Nova.route_to_file("/about")
Nova.route_to_file("/api/hello")

# Exercise MIME type detection
println("  → Testing MIME types...")
Nova.get_mime_type("style.css")
Nova.get_mime_type("image.png")
Nova.get_mime_type("script.js")
Nova.get_mime_type("icon.svg")

# Exercise HTML rendering
println("  → Testing rendering...")
html = Nova.render("<h1>Test</h1>", title="Test Page", auto_styles=false)

# Exercise SCSS processing
println("  → Testing SCSS processing...")
scss = "\$color: #333; body { color: \$color; }"
css = Nova.process_scss(scss)

# Create a handler and simulate request
println("  → Testing handler creation...")
# Use smart defaults (will find src/pages)
handler = Nova.create_handler()

# Simulate HTTP requests (without actually starting server)
println("  → Testing request handling...")
test_req = HTTP.Request("GET", "/")
try
    # This might fail if pages don't exist, but it exercises the code path
    response = handler(test_req)
catch e
    # Expected - we're just exercising code paths
end

# Exercise file system utilities
println("  → Testing utilities...")
if isdir("src/pages")
    files = Nova.find_files("src/pages", [".jl"])
end

println("✓ Precompilation script completed successfully!")
println("  Framework is ready for AOT compilation.")
