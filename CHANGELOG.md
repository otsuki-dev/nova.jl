# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

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
