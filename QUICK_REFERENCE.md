# 📋 Nova.jl - Referência Rápida

## 🚀 Comandos

```bash
# Desenvolvimento (hot reload)
julia nova dev

# Build para produção
julia nova build

# Servidor de produção
julia nova start

# Ajuda
julia nova help
```

## ⚙️ Opções

```bash
# Porta customizada
julia nova dev --port 3000

# Host customizado
julia nova start --host 0.0.0.0

# Ambos
julia nova start --host 0.0.0.0 --port 8080

# Logs detalhados
julia nova dev --verbose
```

## 📁 Estrutura de Arquivos

```
nova.jl/
├── nova                 # CLI tool
├── src/Nova.jl         # Framework core
├── pages/              # Suas páginas
│   ├── index.jl       # / route
│   ├── about.jl       # /about route
│   └── api/           # /api/* routes
│       └── hello.jl
├── public/             # Static assets
│   └── favicon.ico
└── build/              # Gerado por 'nova build'
    └── start.jl       # Production script
```

## 📄 Criar uma Página

**`pages/hello.jl`:**
```julia
function handler(req)
    return """
    <html>
        <body>
            <h1>Hello from Nova.jl!</h1>
        </body>
    </html>
    """
end
```

Acesse: `http://localhost:2518/hello`

## 🔌 Criar API Endpoint

**`pages/api/users.jl`:**
```julia
using HTTP
using JSON

function handler(req)
    data = Dict(
        "users" => [
            Dict("id" => 1, "name" => "Alice"),
            Dict("id" => 2, "name" => "Bob")
        ]
    )
    
    return HTTP.Response(
        200,
        ["Content-Type" => "application/json"],
        JSON.json(data)
    )
end
```

Acesse: `http://localhost:2518/api/users`

## 🎨 Rotas

```
pages/index.jl          → /
pages/about.jl          → /about
pages/contact.jl        → /contact
pages/blog/post.jl      → /blog/post
pages/api/hello.jl      → /api/hello
```

## 🏗️ Workflow

### Desenvolvimento
```bash
# 1. Criar projeto
mkdir myapp && cd myapp

# 2. Criar estrutura
mkdir -p pages public src

# 3. Copiar Nova.jl para src/

# 4. Criar páginas
cat > pages/index.jl << 'EOF'
function handler(req)
    return "<h1>My App</h1>"
end
EOF

# 5. Iniciar dev server
julia nova dev
```

### Produção
```bash
# 1. Build
julia nova build

# 2. Testar localmente
cd build && julia start.jl

# 3. Deploy
scp -r build/ user@server:/opt/myapp/

# 4. No servidor
cd /opt/myapp/build
julia start.jl
```

## 🐳 Docker

**Dockerfile:**
```dockerfile
FROM julia:1.11
WORKDIR /app
COPY build/ .
RUN julia --project=. -e 'using Pkg; Pkg.instantiate()'
EXPOSE 2518
ENV NOVA_HOST=0.0.0.0
CMD ["julia", "start.jl"]
```

**Build e Run:**
```bash
julia nova build
docker build -t myapp .
docker run -p 2518:2518 myapp
```

## 🔧 Variáveis de Ambiente

```bash
NOVA_HOST=0.0.0.0      # Host (default: 127.0.0.1)
NOVA_PORT=2518         # Port (default: 2518)
```

## 📊 Exemplo Completo

**`pages/index.jl`:**
```julia
function handler(req)
    return """
    <!DOCTYPE html>
    <html>
    <head>
        <title>My Nova App</title>
    </head>
    <body>
        <h1>Welcome to Nova.jl</h1>
        <nav>
            <a href="/">Home</a>
            <a href="/about">About</a>
            <a href="/api/hello">API</a>
        </nav>
    </body>
    </html>
    """
end
```

**`pages/about.jl`:**
```julia
function handler(req)
    return """
    <h1>About</h1>
    <p>This is a Nova.jl application</p>
    <a href="/">Back to home</a>
    """
end
```

**`pages/api/hello.jl`:**
```julia
using HTTP
using JSON

function handler(req)
    return HTTP.Response(
        200,
        ["Content-Type" => "application/json"],
        JSON.json(Dict("message" => "Hello API!"))
    )
end
```

## 🎯 Tips

### Hot Reload
- Edite qualquer arquivo `.jl` em `pages/`, `src/`, ou `components/`
- Servidor recarrega automaticamente
- Sem necessidade de restart

### Static Files
- Coloque em `public/`
- Acesso direto: `http://localhost:2518/arquivo.png`

### Performance
- Use `nova start` em produção (sem hot reload)
- Considere precompilação: `Pkg.precompile()`
- System image para startup mais rápido

### Debugging
```bash
# Logs detalhados
julia nova dev --verbose

# Check erros
julia nova dev 2>&1 | grep ERROR
```

## 🆘 Troubleshooting

**Porta em uso:**
```bash
# Usar outra porta
julia nova dev --port 3000

# OU matar processo
lsof -ti:2518 | xargs kill -9
```

**Módulo não encontrado:**
```bash
# Ativar projeto e instalar deps
julia --project=. -e 'using Pkg; Pkg.instantiate()'
```

**Hot reload não funciona:**
```bash
# Verificar permissões
ls -la pages/

# Restart manualmente
^C
julia nova dev
```

## 📚 Recursos

- **Docs**: Ver arquivos `.md` no repo
- **Examples**: `examples/` directory
- **Tests**: `test/runtests.jl`
- **GitHub**: https://github.com/otsuki-dev/nova.jl

## ⌨️ Atalhos

```bash
# Alias úteis (adicione no .bashrc/.zshrc)
alias nd='julia nova dev'
alias nb='julia nova build'
alias ns='julia nova start'
alias nh='julia nova help'
```

---

**Happy Coding! 🚀**
