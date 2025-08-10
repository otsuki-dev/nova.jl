# Nova.jl

`Nova.jl` is a minimal framework for building fast web applications in Julia.

## Quick Start

1. **Install Julia** (version 1.6+) from [julialang.org](https://julialang.org)

2. **Clone this repository**:
```sh
git clone https://github.com/otsuki-dev/nova.jl.git
cd nova.jl
```

3. **Install dependencies**:
```julia
using Pkg
Pkg.activate(".")
Pkg.instantiate()
```

4. **Start the development server**:
```sh
julia dev.server.jl
```

5. **Visit** `http://localhost:2518`

## How to use

The file system is the main API. Every `.jl` file in `pages/` becomes a route.

Create `pages/index.jl`:

```julia
using Nova

function handler()
    return Nova.render("<div>Welcome to Nova.jl!</div>")
end
```

Start the development server:

```sh
julia dev.server.jl
```

Visit `http://localhost:2518`.

You get:

- Automatic hot reloading
- Fast server-side rendering
- Simple routing based on file structure

### Project structure

```
NovaApp/
├── pages/      # Routes
│   └── index.jl
├── api/        # API endpoints
├── public/     # Static files
├── styles/     # CSS/SCSS
└── nova.jl     # CLI launcher
```

### Static files

Files in `public/` are served at the root URL.

```
public/logo.png → http://localhost:2518/logo.png
```

### Styles

All `.css` and `.scss` files in `styles/` are injected into every page.

Example:

```scss
// styles/main.scss
body { background: #222; color: #fff; }
```

### Example: Using an image and style

```julia
# pages/index.jl
function handler()
    return Nova.render("""
    <img src="/logo.png">
    <button class="btn">Click</button>
    """)
end
```

### Production

```sh
julia nova.jl
```

### Why Nova.jl?

- No configuration needed
- Instant hot reloading
- Simple, file-based routing
- Works with CSS and SCSS