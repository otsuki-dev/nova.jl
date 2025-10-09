using Test
using HTTP

# Load Nova.jl module
include("../src/Nova.jl")
using .Nova

@testset "Nova.jl Framework Tests" begin
    
    @testset "Utils.MIME" begin
        @test Nova.get_mime_type("style.css") == "text/css"
        @test Nova.get_mime_type("script.js") == "application/javascript"
        @test Nova.get_mime_type("image.png") == "image/png"
        @test Nova.get_mime_type("icon.svg") == "image/svg+xml"
        @test Nova.get_mime_type("unknown.xyz") == "application/octet-stream"
    end
    
    @testset "Rendering.Styles" begin
        # Test SCSS variable processing
        scss_content = """
        \$primary: #365EE5;
        body {
            color: \$primary;
        }
        """
        
        processed = Nova.process_scss(scss_content)
        @test contains(processed, "#365EE5")
        @test !contains(processed, "\$primary")
        
        # Test comment removal
        scss_with_comments = "// This is a comment\nbody { color: red; }"
        css = Nova.process_scss(scss_with_comments)
        @test !contains(css, "//")
    end
    
    @testset "Rendering.HTML" begin
        html = Nova.render("<h1>Test</h1>", auto_styles=false, title="Test Page")
        
        @test contains(html, "<!DOCTYPE html>")
        @test contains(html, "<h1>Test</h1>")
        @test contains(html, "<title>Test Page</title>")
        @test contains(html, "charset=\"UTF-8\"")
    end
    
    @testset "Server.Router" begin
        # Create temporary pages directory for testing
        test_pages_dir = mktempdir()
        
        # Create a test page
        test_page = joinpath(test_pages_dir, "test.jl")
        write(test_page, """
        function handler()
            return "Test Page"
        end
        """)
        
        # Test route_to_file
        result = Nova.route_to_file("/test", test_pages_dir)
        @test result !== nothing
        @test endswith(result, "test.jl")
        
        # Test non-existent route
        result = Nova.route_to_file("/nonexistent", test_pages_dir)
        @test result === nothing
        
        # Cleanup
        rm(test_pages_dir, recursive=true)
    end
    
    @testset "Server.Server" begin
        # Test handler creation
        handler = Nova.create_handler()
        @test handler isa Function
        
        # Test basic request
        req = HTTP.Request("GET", "/nonexistent")
        response = handler(req)
        @test response.status == 404
        @test contains(String(response.body), "404")
    end
end

println("\n✅ All tests passed!")
