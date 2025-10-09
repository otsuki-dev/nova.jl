# Nova.jl - Quick Start Guide

## 🚀 Getting Started in 30 Seconds

### 1. Run the Development Server

```bash
julia nova dev
```

Visit: http://localhost:2518

### 2. Create Your First Page

Create `pages/hello.jl`:

```julia
function handler()
    return """
    <!DOCTYPE html>
    <html>
    <head><title>Hello</title></head>
    <body>
        <h1>Hello from Nova.jl!</h1>
    </body>
    </html>
    """
end
```

Visit: http://localhost:2518/hello

### 3. Create an API Endpoint

Create `pages/api/data.jl`:

```julia
using HTTP
using JSON

function handler()
    data = Dict("message" => "Hello API!")
    return HTTP.Response(200, 
        ["Content-Type" => "application/json"],
        JSON.json(data)
    )
end
```

Visit: http://localhost:2518/api/data

## 📁 Project Structure

```
my-nova-app/
├── pages/          # Your routes
│   ├── index.jl   # / route
│   ├── about.jl   # /about route
│   └── api/
│       └── data.jl # /api/data route
├── public/         # Static files
└── nova           # CLI tool
```

## 🎯 Core Philosophy

Nova.jl focuses on:

1. **Performance** - Fast HTTP.jl server
2. **Simplicity** - File-based routing, no config
3. **Pure HTML** - No styling framework, you choose
4. **Hot Reload** - Instant feedback during development

## 📝 CLI Commands

```bash
# Development server with hot reload
julia nova dev

# Custom port
julia nova dev --port 3000

# Show help
julia nova help
```

## 🔥 Hot Reload

Any changes to `.jl` files in `pages/` are detected automatically.
Just save and refresh your browser!

## 🎨 Styling

Nova.jl doesn't include CSS by default. Add your own:

```julia
function handler()
    return """
    <!DOCTYPE html>
    <html>
    <head>
        <style>
            body { font-family: sans-serif; }
            h1 { color: #333; }
        </style>
    </head>
    <body>
        <h1>Styled page</h1>
    </body>
    </html>
    """
end
```

Or link to external CSS:

```html
<link rel="stylesheet" href="/style.css">
```

Place `style.css` in `public/` folder.

## 🚀 Next Steps

- Read [ARCHITECTURE.md](ARCHITECTURE.md) to understand the framework
- Check [examples/](examples/) for more examples
- See [CONTRIBUTING.md](CONTRIBUTING.md) to contribute

---

**Happy coding with Nova.jl! 🎉**
