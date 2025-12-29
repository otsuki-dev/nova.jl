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

    @testset "Rendering.Template" begin
        # Test variable substitution
        data = Dict("name" => "World")
        @test Nova.render_view("Hello {{name}}!", data) == "Hello World!"
        
        # Test missing variable (should be empty)
        @test Nova.render_view("Hello {{missing}}!", data) == "Hello !"
        
        # Test nested object access (dot notation simulation)
        # Note: Our simple engine currently handles flat keys mostly, 
        # but let's test what we implemented (simple keys)
        
        # Test Sections (Lists)
        list_data = Dict("items" => [
            Dict("val" => "A"),
            Dict("val" => "B")
        ])
        list_template = "{{#items}}{{val}}{{/items}}"
        @test Nova.render_view(list_template, list_data) == "AB"
        
        # Test Sections (Boolean/Truthiness)
        bool_data = Dict("show" => true, "hide" => false, "val" => "Shown")
        @test Nova.render_view("{{#show}}{{val}}{{/show}}", bool_data) == "Shown"
        @test Nova.render_view("{{#hide}}{{val}}{{/hide}}", bool_data) == ""
    end
    
    @testset "Rendering.HTML (Template Integration)" begin
        # Create a temporary template file
        template_content = "<h1>Hello {{name}}</h1>"
        template_path = joinpath(mktempdir(), "test.html")
        write(template_path, template_content)
        
        data = Dict("name" => "Integration")
        
        # Test render(path, data)
        html = Nova.render(template_path, data, title="Integration Test")
        
        @test contains(html, "<!DOCTYPE html>")
        @test contains(html, "<h1>Hello Integration</h1>")
        @test contains(html, "<title>Integration Test</title>")
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
