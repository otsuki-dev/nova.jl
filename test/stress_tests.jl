using Test
using HTTP
using Dates

# We assume Nova is already loaded by runtests.jl
# using .Nova

@testset "Performance & Robustness" begin
    
    # Setup Test Environment
    TEST_DIR = mktempdir()
    PAGES_DIR = joinpath(TEST_DIR, "pages")
    STYLES_DIR = joinpath(TEST_DIR, "styles")
    PUBLIC_DIR = joinpath(TEST_DIR, "public")
    
    mkpath(PAGES_DIR)
    mkpath(STYLES_DIR)
    mkpath(PUBLIC_DIR)
    
    # Helper to create files
    function create_file(path, content)
        mkpath(dirname(path))
        write(path, content)
    end
    
    @testset "Routing Performance (Cache)" begin
        create_file(joinpath(PAGES_DIR, "perf_test.jl"), """
        function handler(req, params)
            return "Performance Test"
        end
        """)
        
        # Cold Start
        t_start = time_ns()
        res_cold = Nova.handle_page_route(joinpath(PAGES_DIR, "perf_test.jl"))
        t_cold = (time_ns() - t_start) / 1e6
        
        @test res_cold == "Performance Test"
        
        # Warm Start (Cached)
        t_start = time_ns()
        res_warm = Nova.handle_page_route(joinpath(PAGES_DIR, "perf_test.jl"))
        t_warm = (time_ns() - t_start) / 1e6
        
        @test res_warm == "Performance Test"
        
        # Warm start should be significantly faster (unless cold start was already super fast)
        # We use a loose check to avoid flakiness in CI
        if t_cold > 1.0 # Only check if cold start took some time
            @test t_warm < t_cold
        end
    end
    
    @testset "Style Processing Performance" begin
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
        
        Nova.clear_style_cache()
        
        # Cold Load
        t_start = time_ns()
        css_cold = Nova.auto_load_styles(STYLES_DIR)
        t_style_cold = (time_ns() - t_start) / 1e6
        
        # Minified CSS should not have spaces after colons
        @test contains(css_cold, "color:red")
        @test !contains(css_cold, "/* Comment */") # Minified
        
        # Warm Load
        t_start = time_ns()
        css_warm = Nova.auto_load_styles(STYLES_DIR)
        t_style_warm = (time_ns() - t_start) / 1e6
        
        @test css_warm == css_cold
        
        if t_style_cold > 1.0
            @test t_style_warm < t_style_cold
        end
    end
    
    @testset "Security: Path Traversal" begin
        # Create a secret file outside public
        secret_file = joinpath(TEST_DIR, "secret.txt")
        write(secret_file, "SECRET_DATA")
        
        # Try to access it via relative path
        res = Nova.serve_static("../secret.txt", PUBLIC_DIR)
        
        # Should be nothing (blocked) or 404, definitely NOT the content
        if res !== nothing
            @test String(res.body) != "SECRET_DATA"
        else
            @test res === nothing
        end
    end
    
    @testset "Robustness: Malformed SCSS" begin
        create_file(joinpath(STYLES_DIR, "bad.scss"), "\$var: ; bad syntax {")
        # Should not throw
        css = Nova.auto_load_styles(STYLES_DIR)
        @test css isa String
    end
    
    @testset "Robustness: Invalid Page" begin
        create_file(joinpath(PAGES_DIR, "no_handler.jl"), "x = 1")
        res = Nova.handle_page_route(joinpath(PAGES_DIR, "no_handler.jl"))
        @test res === nothing
    end
    
    # Cleanup
    rm(TEST_DIR, recursive=true)
end
