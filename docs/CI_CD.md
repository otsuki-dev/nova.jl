# CI/CD Configuration

Nova.jl uses GitHub Actions for continuous integration and automated testing.

## Workflows

### 1. Tests & CI (`tests.yml`)
Runs on every push and pull request.

**What it does:**
- Tests on Julia 1.10, 1.11, 1.12
- Tests on Linux, macOS, Windows
- Runs full test suite (`test/runtests.jl`)
- Runs performance benchmarks

**Matrix:**
- Julia versions: 1.10, 1.11, 1.12
- Operating systems: Ubuntu, macOS, Windows
- ~36 job combinations (optimized for speed)

### 2. Build Status (`build.yml`)
Verifies package can be imported and used.

**What it does:**
- Checks Nova.jl can be imported
- Tests handler creation
- Validates package metadata

### 3. Documentation (`docs.yml`)
Checks documentation integrity.

**What it does:**
- Validates markdown syntax
- Checks for broken documentation
- Runs on documentation changes

---

## Local Testing

Before pushing, run tests locally:

```bash
# Run full test suite
julia test/runtests.jl

# Run specific tests
julia test/stress_tests.jl

# Run benchmarks
julia test/bench.jl

# Check installation
julia --project -e 'using Nova; println("OK")'
```

---

## CI Status

Check build status:
- **GitHub Actions**: https://github.com/otsuki-dev/nova.jl/actions
- **Pull Requests**: Automatic checks on every PR

---

## Badge URLs

Add to your documentation:

```markdown
[![Tests](https://github.com/otsuki-dev/nova.jl/workflows/Tests%20&%20CI/badge.svg)](https://github.com/otsuki-dev/nova.jl/actions/workflows/tests.yml)

[![Build Status](https://github.com/otsuki-dev/nova.jl/workflows/Build%20Status/badge.svg)](https://github.com/otsuki-dev/nova.jl/actions/workflows/build.yml)
```
