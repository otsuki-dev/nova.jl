"""
    Benchmark: Nova.jl vs Other Frameworks

Compares Nova.jl performance against other Julia and Python web frameworks.
Run on your local machine for consistent results.

Requirements:
- Julia 1.12+
- HTTP.jl, Oxygen.jl (Julia frameworks)
- Python 3.10+ with FastAPI, Flask
- wrk (Apache Bench alternative)

Usage:
    julia test/benchmark_comparison.jl [--all|--julia|--python]
"""

using HTTP
using JSON
using Sockets
using Statistics
using Dates

# ============================================================================
# Configuration
# ============================================================================

const BENCHMARKS = Dict(
    :nova => Dict(
        :port => 2518,
        :cmd => "julia --project -e 'using Nova; Nova.start_server(port=2518, verbose=false)'",
        :warmup => 100,
        :requests => 10000,
        :concurrency => 100,
        :name => "Nova.jl"
    ),
    # Add other Julia frameworks here
    # :oxygen => Dict(...)
)

const TIMEOUT = 30  # seconds to wait for server startup
const RESULTS = Dict{String, Dict}()

# ============================================================================
# Utilities
# ============================================================================

"""Check if a port is open."""
function is_port_open(port::Int)::Bool
    try
        socket = Sockets.TCPSocket()
        connect(socket, Sockets.InetAddr(Sockets.localhost, port))
        close(socket)
        return true
    catch
        return false
    end
end

"""Wait for server to start."""
function wait_for_server(port::Int, timeout::Int=TIMEOUT)::Bool
    start_time = time()
    while time() - start_time < timeout
        if is_port_open(port)
            sleep(0.5)  # Extra buffer
            return true
        end
        sleep(0.1)
    end
    return false
end

"""Run a single benchmark against a server."""
function run_benchmark(name::String, port::Int, config::Dict)::Dict
    println("\n" * "="^60)
    println("Benchmarking: $name")
    println("="^60)
    
    results = Dict(
        :name => name,
        :port => port,
        :status => "pending",
        :error => nothing,
        :warmup => 0,
        :throughput => 0.0,
        :latency_mean => 0.0,
        :latency_p95 => 0.0,
        :latency_p99 => 0.0,
        :memory => 0.0
    )
    
    try
        # Warmup requests
        println("Warming up with $(config[:warmup]) requests...")
        for i in 1:config[:warmup]
            try
                HTTP.get("http://localhost:$port/", connect_timeout=2, readtimeout=5)
            catch e
                println("Warmup request $i failed: $e")
            end
            if i % 50 == 0
                print(".")
            end
        end
        println(" ✓")
        
        # Benchmark requests
        println("Running $(config[:requests]) benchmark requests...")
        latencies = Float64[]
        
        start_time = time()
        errors = 0
        
        for i in 1:config[:requests]
            try
                req_start = time()
                response = HTTP.get("http://localhost:$port/", 
                    connect_timeout=2, 
                    readtimeout=5)
                req_time = (time() - req_start) * 1000  # ms
                
                if response.status == 200
                    push!(latencies, req_time)
                else
                    errors += 1
                end
            catch e
                errors += 1
            end
            
            if i % 1000 == 0
                print(".")
            end
        end
        
        elapsed = time() - start_time
        println(" ✓")
        
        # Calculate statistics
        successful_requests = config[:requests] - errors
        throughput = successful_requests / elapsed
        
        sort!(latencies)
        
        results[:status] = "success"
        results[:throughput] = round(throughput; digits=2)
        results[:requests_total] = config[:requests]
        results[:requests_successful] = successful_requests
        results[:requests_failed] = errors
        results[:elapsed_time] = round(elapsed; digits=2)
        results[:latency_mean] = round(mean(latencies); digits=2)
        results[:latency_min] = round(minimum(latencies); digits=2)
        results[:latency_max] = round(maximum(latencies); digits=2)
        results[:latency_p95] = round(latencies[Int(ceil(0.95 * length(latencies)))]; digits=2)
        results[:latency_p99] = round(latencies[Int(ceil(0.99 * length(latencies)))]; digits=2)
        
        # Print results
        println("\nResults for $name:")
        println("  Throughput:    $(results[:throughput]) req/s")
        println("  Total time:    $(results[:elapsed_time])s")
        println("  Success rate:  $(round(100 * successful_requests / config[:requests]; digits=1))%")
        println("  Latency mean:  $(results[:latency_mean])ms")
        println("  Latency p95:   $(results[:latency_p95])ms")
        println("  Latency p99:   $(results[:latency_p99])ms")
        
    catch e
        results[:status] = "error"
        results[:error] = string(e)
        println("✗ Error: $e")
    end
    
    return results
end

# ============================================================================
# Main Benchmark Suite
# ============================================================================

function main()
    println("\n")
    println("╔" * "="^58 * "╗")
    println("║ Nova.jl Framework Benchmark Suite                        ║")
    println("║ $(Dates.now())                                          ║")
    println("╚" * "="^58 * "╝")
    
    if length(ARGV) > 0 && ARGV[1] == "--help"
        println("\nUsage:")
        println("  julia test/benchmark_comparison.jl [options]")
        println("\nOptions:")
        println("  --help      Show this help message")
        println("  --nova      Benchmark Nova.jl only (default)")
        println("  --all       Benchmark all configured frameworks")
        return
    end
    
    benchmark_names = if length(ARGV) > 0 && ARGV[1] == "--all"
        collect(keys(BENCHMARKS))
    else
        [:nova]
    end
    
    # Start servers and run benchmarks
    processes = Dict()
    
    try
        for framework_name in benchmark_names
            config = BENCHMARKS[framework_name]
            port = config[:port]
            
            println("\n\n📦 Starting $(config[:name])...")
            
            # Start server in background
            # Note: In production, use proper process management
            # For now, assuming server is already running or started manually
            
            if !wait_for_server(port)
                println("✗ Failed to start server on port $port")
                println("  Make sure to start the server manually:")
                println("  $(config[:cmd])")
                continue
            end
            
            println("✓ $(config[:name]) ready on localhost:$port")
            
            # Run benchmark
            result = run_benchmark(config[:name], port, config)
            RESULTS[config[:name]] = result
        end
        
    finally
        # Summary
        println("\n\n" * "="^60)
        println("BENCHMARK SUMMARY")
        println("="^60)
        
        println("\n┌─ Throughput (req/s) ─────────────────────────────────────┐")
        for (name, result) in sort(RESULTS; by=x->x[2][:throughput]; rev=true)
            status_icon = result[:status] == "success" ? "✓" : "✗"
            throughput = result[:throughput]
            bar_length = Int(floor(throughput / 100))
            bar = "█" ^ min(bar_length, 30)
            println("│ $status_icon $(lpad(name, 15)) $(lpad(Int(round(throughput)), 6)) req/s  $bar")
        end
        println("└" * "─"^58 * "┘")
        
        println("\n┌─ Latency (ms, mean) ─────────────────────────────────────┐")
        for (name, result) in sort(RESULTS; by=x->x[2][:latency_mean])
            if result[:status] == "success"
                latency = result[:latency_mean]
                bar_length = Int(floor(latency / 2))
                bar = "█" ^ min(bar_length, 20)
                println("│ ✓ $(lpad(name, 15)) $(lpad(latency, 6))ms     $bar")
            end
        end
        println("└" * "─"^58 * "┘")
        
        # Export JSON results
        results_file = "benchmark_results_$(Dates.format(now(), "yyyy-mm-dd_HH-MM-SS")).json"
        open(results_file, "w") do f
            JSON.print(f, RESULTS)
        end
        println("\n✓ Results saved to: $results_file")
        
    end
end

# ============================================================================
# Quick Nova.jl Benchmark (no dependencies)
# ============================================================================

"""
Run a quick Nova.jl benchmark without external tools.
Assumes server is already running on port 2518.
"""
function quick_benchmark()
    println("\n" * "="^60)
    println("Quick Nova.jl Benchmark")
    println("="^60)
    println("\nAssuming Nova.jl server running on http://localhost:2518")
    println("Start with: julia -e 'using Nova; Nova.start_server()'")
    
    if !wait_for_server(2518; timeout=5)
        println("✗ Server not responding on port 2518")
        return
    end
    
    println("✓ Server connected")
    
    # Run quick benchmark
    result = run_benchmark("Nova.jl", 2518, Dict(
        :warmup => 100,
        :requests => 5000,
        :concurrency => 50
    ))
    
    if result[:status] == "success"
        println("\n✓ Benchmark complete!")
    end
end

# ============================================================================
# Entry Point
# ============================================================================

if isempty(ARGV) || (length(ARGV) == 1 && ARGV[1] == "--quick")
    quick_benchmark()
else
    main()
end
