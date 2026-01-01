# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [0.0.6] - 2026-01-01

### Added
- **Project cleanup**: Comprehensive repository cleanup — all test and benchmark scripts moved to the `test/` directory
- **Automatic diagnostics**: Added `diagnose.sh` to verify framework health and common environment issues
- **Test documentation**: Updated `test/README.md` with a complete guide to the available tests and how to run them

### Removed
- **Obsolete files**: Removed legacy `nova.jl`, `dev.server.jl`, and the root-level `build/` directory; removed empty `api/` folder
- **Duplicates**: Eliminated duplicated or obsolete test files

### Performance
- **Critical optimizations**: Improvements implemented across the router and HTTP handling
  - Fast path for precompiled/static routes (achieving ~85–88% efficiency vs raw HTTP.jl)
  - Eliminated unnecessary allocations in route matching
  - Preallocated HTTP headers for cached responses
  - TCP tuning (`tcp_nodelay`, `reuseaddr`) where supported
- **Benchmarks**: ~10,600–11,000 requests/sec (100 concurrent connections, 4 threads)
- **Framework overhead**: ~15% above raw HTTP.jl — among the most efficient full-stack frameworks in the Julia ecosystem

### Changed
- **Build behavior**: `nova build` now always generates precompiled/static route files for production builds
- **Repository layout**: Project root contains only essential files after cleanup

### Future Plans
- **Custom HTTP engine (long-term)**: We plan to develop a native, full-Julia HTTP engine to overcome current limits of `HTTP.jl` (observed ~12.5k req/s) and target significantly higher per-process throughput (50k–100k+ req/s) through low-level optimizations and tighter integration with Julia's concurrency and memory model.

---

## [0.0.5] - 2026-01-01

### High Performance
- **Radix Tree Router**: Replaced the linear routing system with a **Trie (Radix Tree)** implementation. This reduces routing complexity from O(n) to O(k), enabling constant-time lookups regardless of the number of routes.
- **Zero-Allocation MIME Types**: Refactored `Utils/MIME.jl` to use a constant lookup table and non-allocating string operations, significantly reducing GC pressure per request.
- **Optimized AOT Compilation**: The `generate_route_file` function now produces highly optimized code with dynamic dispatch logic, supporting multiple handler signatures (`handler()`, `handler(params)`, `handler(req, params)`) without runtime errors.

### Bug Fixes
- **World Age Safety**: Fixed `MethodError` and world age issues in `Router.jl` by correctly using `Base.invokelatest` for dynamic handler execution.
- **Generated Code Safety**: Fixed module name sanitization in AOT builds to handle special characters (like `[id]`) correctly.
- **Dependency Management**: Fixed missing `using Nova` and `using HTTP` in generated route files.

## [0.1.0] - 2025-12-31

### Milestone: First Major Release & Registry Preparation
- **Registry Ready**: Updated `Project.toml` with full `[compat]` bounds for all dependencies, meeting Julia General Registry requirements.
- **Starter Template**: Created `nova-starter` directory with a clean, production-ready project structure for new users.
- **Performance**: Zero-latency routing, AOT optimizations, and asset caching are now standard.

### Architecture
- **Modern Directory Structure**: Adopted the `src/` convention. Pages are now located in `src/pages`, components in `src/components`, and styles in `src/styles`.
- **Smart Defaults**: The framework automatically detects if the project uses the modern `src/` structure or the legacy root-level structure, ensuring backward compatibility.
- **CLI Updates**: The `nova` CLI tool (`dev`, `build`, `start`) has been updated to support the new directory structure seamlessly.

### Security
- **Path Traversal Fix**: Patched a vulnerability in `Assets.jl` that allowed access to files outside the public directory.

## [0.0.4] - 2025-12-31

### Performance
- **Zero-Latency Routing**: Implemented `PAGE_CACHE` to cache compiled page modules, eliminating recompilation overhead on subsequent requests.
- **Static Route Optimization**: Added support for `STATIC_ROUTES` to bypass filesystem scanning in production (AOT) builds.
- **Asset Caching**: Implemented `STYLE_CACHE` for processed SCSS/CSS and added HTTP `Cache-Control` headers for static assets.
- **Minification**: Added automatic CSS minification (`minify_css`) to reduce payload size.

### Architecture
- **AOT Readiness**: Refactored `Server.jl` to prioritize pre-registered static routes, enabling true "tree-shaking" of routing logic in compiled builds.
- **Robust Execution**: Enhanced dynamic handler execution with `Base.invokelatest` to resolve world age issues in Julia 1.12+.

### Changed
- **Hot Reload**: Updated `HotReload.jl` to automatically clear page and style caches upon file modification.
- **Router**: Optimized `handle_page_route` to use cached modules whenever possible.

## [0.0.3] - 2025-12-29

### Added
- **API Routing Support**: Implemented dedicated routing for the `api/` directory. Files in `api/` are now automatically mapped to `/api/*` routes (Task A-2).
- **Environment Activation**: The CLI now automatically activates the project environment (`Pkg.activate(@__DIR__)`) to ensure dependencies are loaded correctly.

### Changed
- **World Age Fixes**: Refactored CLI commands (`dev`, `start`, `build`) to use `@eval` and `Base.invokelatest` correctly, resolving "world age" warnings and errors in Julia 1.12.
- **Template Module**: Simplified `Rendering.Template` module structure and fixed export issues that were causing `UndefVarError` in tests.
- **HTML Rendering**: Updated `Rendering.HTML` to integrate correctly with the refactored Template module.

### Fixed
- **Dependency Issues**: Corrected the UUID for `SQLite` in `Project.toml` to match the General registry.
- **Syntax Errors**: Fixed a syntax error in `src/Rendering/Template.jl`.
- **Port Conflicts**: Improved error handling for port conflicts during development server startup.

## [0.0.2] - 2025-10-08

### Added
- Complete CLI implementation with professional terminal output
- Production build system via `julia nova build` command
- Production server mode via `julia nova start` command
- Professional terminal UI with ANSI colors and Unicode symbols
- Comprehensive documentation suite (12 guides)
- Docker support with configuration examples and deployment guides
- Environment variable configuration support (NOVA_HOST, NOVA_PORT)
- Quick reference guide for CLI commands
- Multi-platform deployment guide (Docker, systemd, AWS, Heroku)

### Changed
- Improved exit behavior with minimal output on Ctrl+C interruption
- Updated help command with complete documentation for all available commands
- Enhanced CLI output with color-coded messages and structured feedback
- Modernized README with professional badges and improved project structure

### Fixed
- Resolved verbose stack traces appearing on normal exit (Ctrl+C)
- Improved world age handling using Base.invokelatest for dynamic code loading
- Enhanced error handling and reporting in production mode

### Documentation
- BUILD_START_GUIDE.md: Complete guide for building and running production servers
- DEPLOY.md: Multi-platform deployment instructions and best practices
- QUICK_REFERENCE.md: Command reference and usage patterns
- STATUS.md: Project status, statistics, and development roadmap
- IMPLEMENTATION_COMPLETE.md: Implementation details and technical summary
- SUMMARY.md: Visual project overview and architecture
- RELEASE_NOTES.md: Detailed release notes for version 0.0.2
- CLI_IMPROVEMENTS.md: CLI enhancement documentation and design decisions

### Testing
- Automated CLI test suite via test_cli.sh script
- All 18 unit tests passing successfully
- Build system validated across multiple scenarios
- Production mode tested and verified

---

## [0.0.1] - 2025-08-09

### Added
- Initial release of Nova.jl web framework
- File-based routing system mapping files to HTTP routes
- Automatic CSS/SCSS compilation and injection into HTML responses
- Static file serving from public/ directory
- Hot reload development server with automatic file watching
- Automatic favicon detection and serving
- Component system with modular architecture support
- Separate production and development server modes
- Custom route configuration support

### Features
- Zero-configuration setup for rapid development
- Fast server-side rendering with minimal overhead
- SCSS variable processing and compilation
- Automatic style discovery and loading
- HTTP server with flexible routing capabilities
- File watching system for development workflow

### Dependencies
- HTTP.jl for web server functionality
- Revise.jl for development hot reloading capabilities
- FileWatching.jl for file system change monitoring
