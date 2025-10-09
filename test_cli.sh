#!/bin/bash

echo "=== Testing nova CLI ==="
echo ""

echo "1. Testing 'nova help':"
julia -- nova help
echo ""

echo "2. Testing 'nova build':"
julia -- nova build
echo ""

echo "3. Build output structure:"
ls -la build/
echo ""

echo "4. Testing production script in build/:"
cd build && timeout 3 julia start.jl &
PID=$!
sleep 2
echo "Server started with PID: $PID"
kill -INT $PID 2>/dev/null
wait $PID 2>/dev/null
cd ..
echo ""

echo "=== All tests complete ==="
