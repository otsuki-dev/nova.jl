# Nova.jl Architecture

## Overview

Nova.jl is a minimal web framework for Julia inspired by modern frameworks like Next.js and Express. It follows a modular architecture with clear separation of concerns.

## Core Principles

1. **Simplicity**: Minimal configuration, maximum productivity
2. **Modularity**: Independent, composable modules
3. **File-based Routing**: Convention over configuration
4. **Developer Experience**: Hot reload, clear errors, fast feedback

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────┐
│                     Nova.jl Core                         │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  ┌─────────────┐  ┌──────────────┐  ┌──────────────┐   │
│  │   Server    │  │  Rendering   │  │   DevTools   │   │
│  ├─────────────┤  ├──────────────┤  ├──────────────┤   │
│  │ Server.jl   │  │ HTML.jl      │  │ HotReload.jl │   │
│  │ Router.jl   │  │ Styles.jl    │  └──────────────┘   │
│  └─────────────┘  │ Assets.jl    │                      │
│                    └──────────────┘                      │
│                                                           │
│  ┌─────────────────────────────────────────────────┐    │
│  │              Utils (MIME, FileSystem)            │    │
│  └─────────────────────────────────────────────────┘    │
│                                                           │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
              ┌────────────────────────┐
              │      HTTP.jl           │
              │   (External Dep)       │
              └────────────────────────┘
```

## Module Breakdown

### Server Module

**Purpose**: Handle HTTP requests and routing

**Components**:
- `Server.jl`: HTTP server configuration using HTTP.jl
- `Router.jl`: File-based routing system

**Responsibilities**:
- Start/stop HTTP server
- Route requests to appropriate handlers
- Handle 404 and 500 errors
- Serve static files

### Rendering Module

**Purpose**: Generate HTML and manage assets

**Components**:
- `HTML.jl`: HTML template rendering
- `Styles.jl`: CSS/SCSS processing and auto-loading
- `Assets.jl`: Static file serving, favicon detection

**Responsibilities**:
- Render complete HTML documents
- Process and inject styles
- Serve static assets (images, fonts, etc.)
- Auto-detect and inject favicons

### DevTools Module

**Purpose**: Development-time tools and utilities

**Components**:
- `HotReload.jl`: File watching and automatic reload

**Responsibilities**:
- Watch files for changes
- Reload modules when files change
- Provide developer feedback

### Utils Module

**Purpose**: Shared utilities

**Components**:
- `MIME.jl`: MIME type detection
- `FileSystem.jl`: File system helpers

**Responsibilities**:
- Determine content types
- File system operations
- Common helper functions

## Request Flow

```
HTTP Request
    │
    ├─→ Static File? ─→ Serve from public/
    │
    ├─→ Route Match? ─→ Load page handler ─→ Render HTML
    │
    └─→ 404 Not Found
```

## File-Based Routing

Nova.jl uses a file-based routing system similar to Next.js:

```
pages/index.jl        → /
pages/about.jl        → /about
pages/docs/guide.jl   → /docs/guide
```

Each page file exports a `handler()` function that returns HTML.

## Extension Points

Nova.jl is designed to be extensible:

1. **Custom Handlers**: Create custom request handlers
2. **Middleware**: Add middleware to the request pipeline (future)
3. **Custom Renderers**: Replace or extend the rendering system
4. **Plugins**: Add functionality via modules (future)

## Performance Considerations

- **Static file serving**: Files are read on each request (caching can be added)
- **SCSS processing**: Basic implementation, suitable for development
- **Hot reload**: Uses polling, ~1s interval by default
- **Module reloading**: Uses `Base.include`, not production-ready

## Future Improvements

1. **Middleware system**: Express-style middleware
2. **API routes**: Dedicated API route handling
3. **Production mode**: Optimizations for deployment
4. **Asset pipeline**: Advanced CSS/JS bundling
5. **SSR/SSG**: Server-side rendering and static generation
6. **WebSocket support**: Real-time communication
7. **Database integration**: Database abstraction layer
8. **Session management**: Built-in session handling
9. **Authentication**: Auth helpers and middleware
10. **Testing utilities**: Framework-specific test helpers

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for details on the architecture and how to contribute.
