# Nova.jl Test Suite

This directory contains tests for the Nova.jl framework.

## Running Tests

Run all tests:
```bash
julia test/runtests.jl
```

Or using Pkg:
```julia
using Pkg
Pkg.test("Nova")
```

## Test Structure

- `runtests.jl` - Main test suite covering all modules

## Test Coverage

The test suite covers:
- ✅ Utils.MIME - MIME type detection
- ✅ Rendering.Styles - SCSS processing
- ✅ Rendering.HTML - HTML rendering
- ✅ Server.Router - File-based routing
- ✅ Server.Server - HTTP server functionality
- ✅ Integration tests - Full server workflow

## Adding Tests

When adding new features, please add corresponding tests to `runtests.jl`.
Follow the existing `@testset` structure.
