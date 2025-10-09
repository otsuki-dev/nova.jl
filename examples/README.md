# Examples

This directory contains example applications built with Nova.jl.

## Available Examples

### 1. Simple Server (`simple_server.jl`)

The most basic Nova.jl server - just responds "OK" to all requests.

```bash
julia examples/simple_server.jl
```

Visit: http://localhost:2518

### 2. Basic Application (`basic/`)

A complete example application showcasing:
- File-based routing
- Static file serving
- Automatic CSS/SCSS loading
- Hot reload during development
- Component system

```bash
julia examples/basic/dev.jl
```

Visit: http://localhost:2518

## Project Structure

### Basic Example Structure

```
examples/basic/
├── dev.jl              # Development server
├── Project.toml        # Dependencies
├── pages/              # Routes
│   ├── index.jl       # / route
│   ├── documentation.jl
│   └── templates.jl
├── components/         # Reusable components
│   └── header.jl
├── public/            # Static assets
│   ├── favicon.png
│   └── *.svg
└── styles/            # CSS/SCSS files
    ├── globals.scss
    └── main.scss
```

## Creating Your Own Application

1. Copy the `basic/` example as a template:
```bash
cp -r examples/basic my-nova-app
cd my-nova-app
```

2. Edit `pages/index.jl` to customize your homepage

3. Run the development server:
```bash
julia dev.jl
```

4. Start building!
