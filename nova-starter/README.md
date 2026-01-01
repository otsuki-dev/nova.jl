# Nova Starter Template

This is the official starter template for [Nova.jl](https://github.com/otsuki-dev/nova.jl).

## Getting Started

1. **Instantiate the project**
   ```bash
   julia --project=. -e 'using Pkg; Pkg.instantiate()'
   ```

2. **Start the development server**
   ```bash
   julia --project=. dev.jl
   ```

3. **Open your browser**
   Visit `http://localhost:2518`

## Structure

- `src/pages/`: Your application routes (file-based routing)
- `src/components/`: Reusable UI components
- `src/styles/`: CSS and SCSS files (auto-processed)
- `public/`: Static assets (images, fonts, etc.)

## Deployment

To build for production:

```bash
julia --project=. -e 'using Nova; Nova.build()'
```
