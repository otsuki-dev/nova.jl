#!/bin/bash

# Kill any running server on port 2518
lsof -ti:2518 | xargs kill -9 2>/dev/null

# Navigate to build directory
cd examples/basic/build

# Start server in background
echo "Starting server..."
julia --threads=auto --project=. start_optimized.jl > server.log 2>&1 &
SERVER_PID=$!

# Wait for server to start
echo "Waiting for server to start..."
sleep 10

# Warmup
echo "Warming up..."
curl -v http://127.0.0.1:2518/
sleep 2

# Run benchmark
echo "Running benchmark..."
julia --threads=auto --project=. ../../../bench.jl

# Kill server
kill $SERVER_PID
echo "Server stopped."
