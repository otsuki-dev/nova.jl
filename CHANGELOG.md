# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [0.0.2] - 2025-10-08

### Added
- ✨ **Complete CLI implementation** with professional terminal output
- 🏗️ **Production build system** (`julia nova build`)
- 🚀 **Production server mode** (`julia nova start`)
- 🎨 **Professional terminal UI** with ANSI colors and Unicode symbols
- 📚 **Comprehensive documentation** (12 guides created)
- 🐳 **Docker support** with examples and guides
- 🔧 **Environment configuration** support (NOVA_HOST, NOVA_PORT)
- 📋 **Quick reference guide** for commands
- 🚢 **Complete deployment guide** (Docker, systemd, AWS, Heroku)

### Changed
- 🎯 **Improved exit behavior** - Subtle output on Ctrl+C (just a newline)
- 📖 **Updated help command** - Complete documentation for all commands
- 🎨 **Enhanced CLI output** - Color-coded messages and clear feedback
- 📚 **Modernized README** - Professional badges and better structure

### Fixed
- 🐛 **Fixed verbose stack traces** on normal exit (Ctrl+C)
- 🔧 **Improved world age handling** with Base.invokelatest
- ✅ **Better error handling** in production mode

### Documentation
- 📄 **BUILD_START_GUIDE.md** - Complete build and production guide
- 📄 **DEPLOY.md** - Multi-platform deployment guide
- 📄 **QUICK_REFERENCE.md** - Quick command reference
- 📄 **STATUS.md** - Project status and statistics
- 📄 **IMPLEMENTATION_COMPLETE.md** - Implementation summary
- 📄 **SUMMARY.md** - Visual project summary
- 📄 **RELEASE_NOTES.md** - Detailed release notes
- 📄 **CLI_IMPROVEMENTS.md** - CLI enhancement documentation

### Testing
- ✅ **Automated CLI tests** via test_cli.sh
- ✅ **All 18 unit tests passing**
- ✅ **Build system validated**
- ✅ **Production mode tested**

---

## [0.0.1] - 2025-08-09

### Added
- 🎉 Initial release of Nova.jl framework
- 📁 File-based routing system
- 🎨 Automatic CSS/SCSS compilation and injection
- 📂 Static file serving from `public/` directory
- 🔥 Hot reload development server
- 🖼️ Automatic favicon detection
- 🧩 Component system with modular architecture
- 🏗️ Production and development server modes
- 🛣️ Custom routes

### Features
- ⚙️ Zero-configuration setup
- ⚡ Fast server-side rendering
- 🎨 SCSS variable processing
- 📦 Automatic style loading
- 🌐 HTTP server with custom routing
- 👀 File watching for development

### Dependencies
- HTTP.jl for web server functionality
- Revise.jl for development hot reloading
- FileWatching.jl for file system monitoring
