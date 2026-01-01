#!/bin/bash

# Nova.jl Diagnostic Script
# Verifica se todos os comandos estão funcionando

echo "╔════════════════════════════════════════════════════════╗"
echo "║           Nova.jl Diagnostic Tool                      ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

cd "$(dirname "$0")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

success() {
    echo -e "${GREEN}✓${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1"
}

warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Test 1: Check if nova exists
echo "1. Checking nova CLI..."
if [ -f "./nova" ]; then
    success "nova CLI found"
else
    error "nova CLI not found!"
    exit 1
fi
echo ""

# Test 2: Check Project.toml
echo "2. Checking Project.toml..."
if [ -f "Project.toml" ]; then
    success "Project.toml found"
    if grep -q "HTTP" Project.toml; then
        success "HTTP dependency found"
    else
        warning "HTTP not in Project.toml dependencies"
    fi
else
    error "Project.toml not found!"
fi
echo ""

# Test 3: Check if port 2518 is available
echo "3. Checking port 2518..."
if lsof -Pi :2518 -sTCP:LISTEN -t >/dev/null 2>&1; then
    warning "Port 2518 is already in use"
    echo "   Run: lsof -ti:2518 | xargs kill -9"
else
    success "Port 2518 is available"
fi
echo ""

# Test 4: Test nova help
echo "4. Testing 'nova help'..."
if ./nova help >/dev/null 2>&1; then
    success "nova help works"
else
    error "nova help failed"
fi
echo ""

# Test 5: Check src/Nova.jl
echo "5. Checking framework files..."
if [ -f "src/Nova.jl" ]; then
    success "src/Nova.jl found"
else
    error "src/Nova.jl not found!"
fi

if [ -d "src/Server" ]; then
    success "src/Server/ found"
else
    error "src/Server/ not found!"
fi
echo ""

# Test 6: Check for pages directory
echo "6. Checking pages directory..."
if [ -d "src/pages" ]; then
    success "src/pages/ found"
elif [ -d "pages" ]; then
    success "pages/ found"
else
    warning "No pages directory found"
    echo "   Create with: mkdir -p src/pages"
fi
echo ""

# Test 7: Try quick dev server start
echo "7. Testing dev server startup (5 seconds)..."
./nova dev > /tmp/nova_test.log 2>&1 &
PID=$!
sleep 5

if ps -p $PID > /dev/null; then
    success "Dev server started successfully"
    kill $PID 2>/dev/null
    wait $PID 2>/dev/null
    
    # Check if it responds
    if curl -s http://127.0.0.1:2518/ > /dev/null 2>&1; then
        success "Server responds to HTTP requests"
    else
        warning "Server started but doesn't respond"
    fi
else
    error "Dev server failed to start"
    echo "   Check log: /tmp/nova_test.log"
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Diagnostic complete!"
echo ""
echo "If you see errors, try:"
echo "  • julia --project=. -e 'using Pkg; Pkg.instantiate()'"
echo "  • lsof -ti:2518 | xargs kill -9  # Free the port"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
