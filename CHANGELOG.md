# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.0.1] - 2025-08-09

### Added
- Initial release of Nova.jl framework
- File-based routing system
- Automatic CSS/SCSS compilation and injection
- Static file serving from `public/` directory
- Hot reload development server
- Automatic favicon detection
- Component system with modular architecture
- Production and development server modes
- Custom routes

### Features
- Zero-configuration setup
- Fast server-side rendering
- SCSS variable processing
- Automatic style loading
- HTTP server with custom routing
- File watching for development

### Dependencies
- HTTP.jl for web server functionality
- Revise.jl for development hot reloading
- FileWatching.jl for file system monitoring
