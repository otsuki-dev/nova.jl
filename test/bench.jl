using HTTP
using Dates
using Statistics

const URL = "http://127.0.0.1:2518/"
const N_REQUESTS = 50000
const CONCURRENCY = 100

function benchmark()
    println("Running benchmark: $N_REQUESTS requests with $CONCURRENCY concurrency...")
    
    times = zeros(Float64, N_REQUESTS)
    completed = Threads.Atomic{Int}(0)
    errors = Threads.Atomic{Int}(0)
    
    start_time = time_ns()
    
    # Use a channel to limit concurrency
    sem = Base.Semaphore(CONCURRENCY)
    
    print("\rProgress: 0 / $N_REQUESTS (0.0%)")
    
    @sync for i in 1:N_REQUESTS
        @async begin
            Base.acquire(sem)
            try
                t0 = time_ns()
                resp = HTTP.get(URL; readtimeout=10, retry=false)
                t1 = time_ns()
                times[i] = (t1 - t0) / 1e9 # seconds
            catch e
                Threads.atomic_add!(errors, 1)
            finally
                Base.release(sem)
                c = Threads.atomic_add!(completed, 1) + 1
                if c % 50 == 0 || c == N_REQUESTS
                    print("\rProgress: $c / $N_REQUESTS ($(round(c/N_REQUESTS*100, digits=1))%)")
                end
            end
        end
    end
    println() # New line after progress bar
    
    total_time = (time_ns() - start_time) / 1e9
    
    successful_requests = N_REQUESTS - errors[]
    if successful_requests == 0
        println("\n❌ All requests failed!")
        return
    end

    # Filter out zeros (failed requests)
    valid_times = filter(>(0), times)
    
    rps = successful_requests / total_time
    avg_latency = isempty(valid_times) ? 0.0 : mean(valid_times) * 1000
    
    println("\nResults:")
    println("  Total Time: $(round(total_time, digits=2)) s")
    println("  Requests: $successful_requests / $N_REQUESTS ($errors errors)")
    println("  RPS: $(round(rps, digits=2)) req/s")
    println("  Avg Latency: $(round(avg_latency, digits=2)) ms")
end

benchmark()
