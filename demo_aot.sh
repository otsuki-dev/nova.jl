#!/bin/bash

# Practical Example: AOT Compilation in Nova.jl
# Demonstrates complete AOT functionality usage

echo "=================================================="
echo "  Nova.jl - AOT Compilation Demo"
echo "=================================================="
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to measure time
time_command() {
    local desc="$1"
    shift
    echo -e "${BLUE}[TEST]${NC} $desc"
    echo -e "${YELLOW}Command:${NC} $@"
    echo ""
    
    /usr/bin/time -f "Time: %E (real) | CPU: %P | Memory: %M KB" "$@"
    
    echo ""
    echo "---"
    echo ""
}

echo -e "${GREEN}PHASE 1: Benchmark WITHOUT sysimage${NC}"
echo "Measuring standard startup time..."
echo ""

time_command "Standard startup (without sysimage)" \
    julia -e 'include("src/Nova.jl"); using .Nova; println("✓ Nova.jl loaded")'

echo ""
echo -e "${GREEN}PHASE 2: Compiling sysimage${NC}"
echo "This will take 3-5 minutes..."
echo ""

# Create sysimage
julia nova compile

echo ""
echo -e "${GREEN}PHASE 3: Benchmark WITH sysimage${NC}"
echo "Measuring startup time with AOT..."
echo ""

time_command "Startup with sysimage" \
    julia --sysimage=build/nova_sys.so -e 'include("src/Nova.jl"); using .Nova; println("✓ Nova.jl loaded (AOT)")'

echo ""
echo -e "${GREEN}PHASE 4: Size comparison${NC}"
echo ""

if [ -f "build/nova_sys.so" ]; then
    SIZE=$(du -h build/nova_sys.so | cut -f1)
    echo "Sysimage: $SIZE"
    ls -lh build/nova_sys.so
fi

echo ""
echo "=================================================="
echo -e "${GREEN}DEMO COMPLETE!${NC}"
echo "=================================================="
echo ""
echo "Next steps:"
echo "  1. Always use: julia --sysimage=build/nova_sys.so"
echo "  2. For production: julia nova build --aot"
echo "  3. Deploy with included sysimage"
echo ""
echo "Documentation: docs/AOT_COMPILATION.md"
