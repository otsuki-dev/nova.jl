# Nova.jl Test Suite

Esta pasta contém todos os testes e benchmarks do framework.

## Estrutura

### Testes Automatizados
- **`runtests.jl`** - Suite principal de testes (use com `julia runtests.jl`)
- **`stress_tests.jl`** - Testes de estresse e robustez
- **`stress_test_old.jl`** - Versão antiga dos testes de estresse (deprecado)

### Benchmarks
- **`bench.jl`** - Benchmark manual de performance HTTP
- **`benchmark.sh`** - Script bash para executar benchmarks automaticamente

### Testes de Funcionalidades
- **`test_aot.sh`** - Testa compilação AOT (Ahead-of-Time) com PackageCompiler
- **`test_cli.sh`** - Testa comandos da CLI (nova build, nova help, etc.)
- **`demo_aot.sh`** - Demonstração prática de AOT compilation

## Como Executar

### Testes Básicos
```bash
julia test/runtests.jl
```

Ou usando Pkg:
```julia
using Pkg
Pkg.test("Nova")
```

### Testes de Estresse
```bash
cd test && julia stress_tests.jl
```

### Benchmarks
```bash
# Benchmark completo (requer servidor rodando)
cd test && ./benchmark.sh

# Ou manualmente
cd test && julia bench.jl
```

### Testes AOT
```bash
cd test && ./test_aot.sh
```

### Testes CLI
```bash
cd test && ./test_cli.sh
```

## Notas

- Os testes assumem que o servidor está rodando na porta 2518
- Para testes que iniciam o servidor automaticamente, certifique-se de que a porta está livre
- Os scripts `.sh` têm permissões de execução

## Test Coverage

The test suite covers:
- ✅ Utils.MIME - MIME type detection
- ✅ Rendering.Styles - SCSS processing
- ✅ Rendering.HTML - HTML rendering
- ✅ Server.Router - File-based routing
- ✅ Server.Server - HTTP server functionality
- ✅ Integration tests - Full server workflow

## Adding Tests

When adding new features, please add corresponding tests to `runtests.jl`.
Follow the existing `@testset` structure.
