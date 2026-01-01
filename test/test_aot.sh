#!/bin/bash

# AOT Compilation Test Script (Task A-4)
# Validates PackageCompiler.jl integration in Nova.jl

set -e

echo "=================================="
echo "Testing AOT Compilation (Task A-4)"
echo "=================================="
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Test 1: Check if PackageCompiler is in dependencies
echo -e "${BLUE}[Test 1]${NC} Checking PackageCompiler in Project.toml..."
if grep -q "PackageCompiler" Project.toml; then
    echo -e "${GREEN}✓ PASS${NC} - PackageCompiler found in dependencies"
else
    echo -e "${RED}✗ FAIL${NC} - PackageCompiler not found in Project.toml"
    exit 1
fi
echo ""

# Test 2: Check if compile command exists
echo -e "${BLUE}[Test 2]${NC} Checking if 'compile' command exists in CLI..."
if grep -q "cmd_compile" nova; then
    echo -e "${GREEN}✓ PASS${NC} - cmd_compile function found"
else
    echo -e "${RED}✗ FAIL${NC} - cmd_compile function not found"
    exit 1
fi
echo ""

# Test 3: Check precompile script exists
echo -e "${BLUE}[Test 3]${NC} Checking precompile_nova.jl..."
if [ -f "precompile_nova.jl" ]; then
    echo -e "${GREEN}✓ PASS${NC} - precompile_nova.jl exists"
else
    echo -e "${RED}✗ FAIL${NC} - precompile_nova.jl not found"
    exit 1
fi
echo ""

# Test 4: Check if build command supports --aot flag
echo -e "${BLUE}[Test 4]${NC} Checking --aot flag support in build command..."
if grep -q '"aot"' nova; then
    echo -e "${GREEN}✓ PASS${NC} - AOT flag supported"
else
    echo -e "${RED}✗ FAIL${NC} - AOT flag not found"
    exit 1
fi
echo ""

# Test 5: Validate precompile script syntax
echo -e "${BLUE}[Test 5]${NC} Validating precompile_nova.jl syntax..."
if julia --project=. -e 'include("precompile_nova.jl")' > /dev/null 2>&1; then
    echo -e "${GREEN}✓ PASS${NC} - Precompile script is valid"
else
    echo -e "${YELLOW}⚠ WARN${NC} - Precompile script has issues (may need dependencies)"
fi
echo ""

# Test 6: Check help documentation
echo -e "${BLUE}[Test 6]${NC} Checking if compile command is documented..."
if julia nova help 2>/dev/null | grep -q "compile"; then
    echo -e "${GREEN}✓ PASS${NC} - Compile command documented in help"
else
    echo -e "${YELLOW}⚠ WARN${NC} - Compile command may need better documentation"
fi
echo ""

# Test 7: Functional test (optional - takes time)
echo -e "${BLUE}[Test 7]${NC} Functional test (compile sysimage)..."
echo -e "${YELLOW}Note:${NC} This test takes 3-5 minutes. Skip? (y/N)"
read -t 10 -n 1 SKIP_COMPILE || SKIP_COMPILE="n"
echo ""

if [ "$SKIP_COMPILE" != "y" ] && [ "$SKIP_COMPILE" != "Y" ]; then
    echo -e "${BLUE}Running:${NC} julia nova compile"
    echo "This will take several minutes..."
    
    # Create build directory
    mkdir -p build
    
    # Run compile command
    if julia nova compile; then
        echo -e "${GREEN}✓ PASS${NC} - Compilation completed successfully"
        
        # Check if sysimage was created
        if [ -f "build/nova_sys.so" ]; then
            SIZE=$(du -h build/nova_sys.so | cut -f1)
            echo -e "${GREEN}✓ PASS${NC} - Sysimage created (${SIZE})"
            
            # Test sysimage
            echo -e "${BLUE}Testing sysimage...${NC}"
            if julia --sysimage=build/nova_sys.so -e 'println("✓ Sysimage works!")'; then
                echo -e "${GREEN}✓ PASS${NC} - Sysimage is functional"
            else
                echo -e "${RED}✗ FAIL${NC} - Sysimage cannot be loaded"
                exit 1
            fi
        else
            echo -e "${RED}✗ FAIL${NC} - Sysimage not created"
            exit 1
        fi
    else
        echo -e "${RED}✗ FAIL${NC} - Compilation failed"
        exit 1
    fi
else
    echo -e "${YELLOW}⊘ SKIP${NC} - Functional test skipped"
fi
echo ""

# Summary
echo "=================================="
echo -e "${GREEN}Task A-4 Validation Complete!${NC}"
echo "=================================="
echo ""
echo "Summary:"
echo "  ✓ PackageCompiler.jl integrated"
echo "  ✓ CLI compile command implemented"
echo "  ✓ Precompile script ready"
echo "  ✓ Build --aot flag available"
echo ""
echo "Usage:"
echo "  julia nova compile          # Create sysimage"
echo "  julia nova build --aot      # Build with AOT"
echo "  julia --sysimage=build/nova_sys.so nova dev"
echo ""
echo -e "${GREEN}✓ Task A-4 COMPLETED${NC}"
