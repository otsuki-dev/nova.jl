using Test
using HTTP
using Dates
using Random

# Include Nova
include("src/Nova.jl")
using .Nova

# Setup Test Environment
const TEST_DIR = mktempdir()
const PAGES_DIR = joinpath(TEST_DIR, "pages")
const STYLES_DIR = joinpath(TEST_DIR, "styles")
const PUBLIC_DIR = joinpath(TEST_DIR, "public")

mkpath(PAGES_DIR)
mkpath(STYLES_DIR)
mkpath(PUBLIC_DIR)

# Helper to create files
function create_file(path, content)
    mkpath(dirname(path))
    write(path, content)
end

println("🔥 Starting Performance & Robustness Stress Test...")
println("📂 Test Directory: $TEST_DIR")

# --- 1. Performance Tests ---

println("\n--- 1. Performance Tests ---")

# 1.1 Routing Performance (Cold vs Warm)
println("\n[Routing] Testing Cold vs Warm Start...")

create_file(joinpath(PAGES_DIR, "perf_test.jl"), """
function handler(req, params)
    return "Performance Test"
end
""")

# Cold Start
t_start = time_ns()
Nova.handle_page_route(joinpath(PAGES_DIR, "perf_test.jl"))
t_cold = (time_ns() - t_start) / 1e6
println("  ❄️ Cold Start: $(round(t_cold, digits=2)) ms")

# Warm Start (Cached)
t_start = time_ns()
Nova.handle_page_route(joinpath(PAGES_DIR, "perf_test.jl"))
t_warm = (time_ns() - t_start) / 1e6
println("  🔥 Warm Start: $(round(t_warm, digits=2)) ms")

if t_warm > t_cold
    println("  ⚠️ WARNING: Warm start is slower! Cache might be ineffective.")
else
    println("  ✅ Cache effective: $(round(t_cold / t_warm, digits=1))x faster")
end

# 1.2 Style Processing Performance
println("\n[Styles] Testing SCSS Processing & Minification...")

scss_content = """
\$color: red;
.test {
    color: \$color;
    background: blue;
    /* Comment */
    padding: 10px;
}
"""
create_file(joinpath(STYLES_DIR, "style.scss"), scss_content)

# Cold Style Load
Nova.clear_style_cache()
t_start = time_ns()
Nova.auto_load_styles(STYLES_DIR)
t_style_cold = (time_ns() - t_start) / 1e6
println("  ❄️ Cold Style Load: $(round(t_style_cold, digits=2)) ms")

# Warm Style Load
t_start = time_ns()
Nova.auto_load_styles(STYLES_DIR)
t_style_warm = (time_ns() - t_start) / 1e6
println("  🔥 Warm Style Load: $(round(t_style_warm, digits=2)) ms")

# 1.3 Concurrency Stress Test
println("\n[Concurrency] Simulating 1000 concurrent requests...")

const N_REQ = 1000
tasks = []
t_start = time_ns()

for i in 1:N_REQ
    push!(tasks, @async begin
        Nova.handle_page_route(joinpath(PAGES_DIR, "perf_test.jl"))
    end)
end

# Wait for all
foreach(wait, tasks)
t_total = (time_ns() - t_start) / 1e9
rps = N_REQ / t_total

println("  🚀 Processed $N_REQ requests in $(round(t_total, digits=4))s")
println("  📊 Throughput: $(round(rps, digits=2)) req/s")


# --- 2. Robustness Tests ---

println("\n--- 2. Robustness Tests ---")

# 2.1 Path Traversal
println("\n[Security] Testing Path Traversal...")
try
    # Attempt to access file outside public dir
    # Note: serve_static joins paths, so we need to check if it prevents escaping
    # Ideally, serve_static should sanitize inputs.
    
    # Create a secret file outside public
    secret_file = joinpath(TEST_DIR, "secret.txt")
    write(secret_file, "SECRET_DATA")
    
    # Try to access it via relative path
    # public_dir is PUBLIC_DIR
    # request path: ../secret.txt
    
    res = Nova.serve_static("../secret.txt", PUBLIC_DIR)
    if res !== nothing && String(res.body) == "SECRET_DATA"
        println("  ❌ VULNERABILITY: Path traversal detected! Accessed ../secret.txt")
    else
        println("  ✅ Path traversal blocked (or file not found via traversal)")
    end
catch e
    println("  ✅ Path traversal caused error (Safe): $e")
end

# 2.2 Malformed SCSS
println("\n[Robustness] Testing Malformed SCSS...")
create_file(joinpath(STYLES_DIR, "bad.scss"), "\$var: ; bad syntax {")
try
    Nova.auto_load_styles(STYLES_DIR)
    println("  ✅ Handled malformed SCSS gracefully (no crash)")
catch e
    println("  ❌ CRASHED on malformed SCSS: $e")
end

# 2.3 Missing Files
println("\n[Robustness] Testing Missing Files...")
res = Nova.handle_page_route(joinpath(PAGES_DIR, "non_existent.jl"))
if res === nothing
    println("  ✅ Handled missing page file correctly")
else
    println("  ❌ Unexpected result for missing file: $res")
end

# 2.4 Invalid Page Module (No handler)
println("\n[Robustness] Testing Invalid Page Module...")
create_file(joinpath(PAGES_DIR, "no_handler.jl"), "x = 1")
res = Nova.handle_page_route(joinpath(PAGES_DIR, "no_handler.jl"))
if res === nothing
    println("  ✅ Handled page without handler() correctly")
else
    println("  ❌ Unexpected result for invalid page: $res")
end

# Cleanup
rm(TEST_DIR, recursive=true)
println("\n✨ Stress Test Complete")
