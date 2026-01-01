<div align="center">

# ⚡ Nova.jl

**A minimal, modular web framework for Julia**

[![Julia Version](https://img.shields.io/badge/julia-v1.6+-9558B2?style=for-the-badge&logo=julia&logoColor=white)](https://julialang.org)
[![Version](https://img.shields.io/badge/version-0.0.7-blue?style=for-the-badge)](CHANGELOG.md)
[![License](https://img.shields.io/badge/license-MIT-green?style=for-the-badge)](LICENSE)
[![Tests](https://github.com/otsuki-dev/nova.jl/workflows/Tests%20&%20CI/badge.svg?style=for-the-badge)](https://github.com/otsuki-dev/nova.jl/actions/workflows/tests.yml)
[![Build Status](https://github.com/otsuki-dev/nova.jl/workflows/Build%20Status/badge.svg?style=for-the-badge)](https://github.com/otsuki-dev/nova.jl/actions/workflows/build.yml)

**[Docs](#-documentation)** • 
**[Quick Start](#-quick-start)** • 
**[Examples](#-examples)** • 
**[Contributing](CONTRIBUTING.md)**

---

</div>

## Features

<table>
<tr>
<td width="50%">

### **Development**
- **Hot Reload** - Instant feedback on changes
- **File-based Routing** - `pages/about.jl` → `/about`
- **Zero Configuration** - Works out of the box
- **Professional CLI** - Beautiful terminal UI

</td>
<td width="50%">

### **Production**
- **One-command Build** - `julia nova build`
- **Optimized Server** - No hot reload overhead
- **Easy Deployment** - Docker, systemd, cloud-ready
- **Environment Config** - Flexible configuration

</td>
</tr>
<tr>
<td width="50%">

### **Minimal Core**
- **Zero CSS** by default
- **No bloat** - Bring your own tools
- **Modular** - 8 independent modules
- **Clean Code** - Easy to understand

</td>
<td width="50%">

### **Full Stack**
- **API Endpoints** - JSON support built-in
- **Static Assets** - Automatic serving
- **MIME Types** - Auto-detection
- **Error Handling** - 404/500 pages

</td>
</tr>
</table>

---

## Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/otsuki-dev/nova.jl.git
cd nova.jl

# 2. Install dependencies
julia --project=. -e 'using Pkg; Pkg.instantiate()'

# 3. Start development server
julia nova dev

# 4. Open browser at http://localhost:2518
```

---

## CLI Commands

<table>
<tr>
<th>Command</th>
<th>Description</th>
<th>Example</th>
</tr>
<tr>
<td><code>julia nova dev</code></td>
<td>Start development server with hot reload</td>
<td><code>julia nova dev --port 3000</code></td>
</tr>
<tr>
<td><code>julia nova build</code></td>
<td>Build application for production</td>
<td><code>julia nova build --aot</code></td>
</tr>
<tr>
<td><code>julia nova compile</code></td>
<td>Compile framework to optimized sysimage (AOT)</td>
<td><code>julia nova compile</code></td>
</tr>
<tr>
<td><code>julia nova start</code></td>
<td>Start production server (no hot reload)</td>
<td><code>julia nova start --host 0.0.0.0</code></td>
</tr>
<tr>
<td><code>julia nova help</code></td>
<td>Show help and available commands</td>
<td><code>julia nova help</code></td>
</tr>
</table>

> **See full CLI reference:** [QUICK_REFERENCE.md](QUICK_REFERENCE.md)

---

## Examples

### Create a Page

File-based routing: `src/pages/hello.jl` → `/hello`

```julia
# src/pages/hello.jl
function handler(req)
    return """
    <html>
        <body>
            <h1>Hello from Nova.jl!</h1>
            <a href="/">Back to home</a>
        </body>
    </html>
    """
end
```

### Create an API Endpoint

```julia
# src/pages/api/users.jl
using HTTP, JSON

function handler(req)
    users = [
        Dict("id" => 1, "name" => "Alice"),
        Dict("id" => 2, "name" => "Bob")
    ]
    
    return HTTP.Response(
        200,
        ["Content-Type" => "application/json"],
        JSON.json(Dict("users" => users))
    )
end
```

### Production Deployment

```bash
# 1. Build for production
julia nova build

# 2. Test locally
cd build && julia start.jl

# 3. Deploy to server
scp -r build/ user@server:/opt/myapp/
ssh user@server "cd /opt/myapp/build && julia start.jl"
```

> 🚢 **Full deployment guide:** [DEPLOY.md](DEPLOY.md)

---

## Project Structure

Nova.jl supports both a modern `src/` structure (recommended) and a legacy root-level structure.

### Modern Structure (Recommended)

```
my-app/
├── src/
│   ├── pages/               Application routes
│   │   ├── index.jl         / route
│   │   └── api/             API endpoints
│   ├── components/          Reusable UI components
│   └── styles/              Global styles (SCSS/CSS)
│
├── public/                  Static files (images, etc.)
├── Project.toml             Dependencies
└── dev.jl                   Development entry point
```

### Legacy Structure

```
my-app/
├── pages/                   Application routes
├── components/              UI components
├── styles/                  Global styles
├── public/                  Static files
└── ...
```

Nova automatically detects which structure you are using.

## Framework Core

```
nova.jl/
├──  src/                     Framework Core (8 modules)
│   ├── Nova.jl               Main module
│   ├── Server/               HTTP server & routing
│   ├── Rendering/            HTML, styles & assets
│   ├── DevTools/             Hot reload system
│   └── Utils/                Helpers & utilities
│
├──  test/                    Test suite (18 tests)
├──  examples/                Example applications
└──   nova                    CLI tool
```

> **Architecture details:** [ARCHITECTURE.md](ARCHITECTURE.md)

## Documentation

<table>
<tr>
<td width="33%">

### **Getting Started**
- [Quick Reference](QUICK_REFERENCE.md)
- [Quickstart Guide](QUICKSTART.md)
- [Architecture](ARCHITECTURE.md)

</td>
<td width="33%">

### **Deployment**
- [Build Guide](BUILD_START_GUIDE.md)
- [Deploy Guide](DEPLOY.md)
- [Production Tips](DEPLOY.md#performance-tips)

</td>
<td width="33%">

### **Project Info**
- [Status & Roadmap](STATUS.md)
- [Changelog](CHANGELOG.md)
- [Contributing](CONTRIBUTING.md)

</td>
</tr>
</table>

---

## Why Nova.jl?

<table>
<tr>
<td width="33%" align="center">

### ⚡ **Fast**
Hot reload in development  
Optimized for production  
Minimal overhead  

</td>
<td width="33%" align="center">

### **Simple**
File-based routing  
Zero configuration  
Clean, modular code  

</td>
<td width="33%" align="center">

### **Ready**
Production builds  
Easy deployment  
Complete tooling  

</td>
</tr>
</table>

---

## Testing

```bash
julia test/runtests.jl
```

[![Tests](https://img.shields.io/badge/tests-18%20passing-success?style=flat-square)](test/runtests.jl)
[![Coverage](https://img.shields.io/badge/coverage-core%20modules-success?style=flat-square)](test/runtests.jl)

All core modules are tested: Server, Routing, Rendering, Hot Reload, Utils

---

## Contributing

We welcome contributions! Here's how:

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing`)
3. Add tests for your changes
4. Ensure tests pass (`julia test/runtests.jl`)
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing`)
7. Open a Pull Request

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

---

## License

Nova.jl is released under the [MIT License](LICENSE).

---

## ⭐ Show Your Support

If you find Nova.jl useful, please consider:

- ⭐ Starring the repository
- 🐛 Reporting bugs via [GitHub Issues](https://github.com/otsuki-dev/nova.jl/issues)
- 💡 Suggesting features
- 📖 Improving documentation
- 🤝 Contributing code

---

<div align="center">

**Built with ⚡ and ❤️ using Julia**

[Website](https://github.com/otsuki-dev/nova.jl) • 
[Documentation](QUICKSTART.md) • 
[Examples](examples/) • 
[Changelog](CHANGELOG.md)

</div>