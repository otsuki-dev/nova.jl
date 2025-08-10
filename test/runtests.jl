using Test

# Carregando o módulo Nova manualmente
include("../src/Nova.jl")
using .Nova

@testset "Nova.jl Tests" begin
    @testset "Basic functionality" begin
        @test Nova.greet() isa Nothing
        
        @test Nova.render("<h1>Test</h1>") isa String
        @test contains(Nova.render("<h1>Test</h1>"), "<!DOCTYPE html>")
        @test contains(Nova.render("<h1>Test</h1>"), "<h1>Test</h1>")
        
        @test Nova.get_mime_type("test.css") == "text/css"
        @test Nova.get_mime_type("test.js") == "application/javascript"
        @test Nova.get_mime_type("test.png") == "image/png"
        @test Nova.get_mime_type("test.unknown") == "application/octet-stream"
    end
    
    @testset "SCSS processing" begin
        scss_content = """
        \$primary: #365EE5;
        body {
            color: \$primary;
        }
        """
        
        processed = Nova.process_scss(scss_content)
        @test contains(processed, "#365EE5")
        @test !contains(processed, "\$primary")
    end
    
    @testset "Auto favicon" begin
        favicon_html = Nova.auto_favicon()
        @test favicon_html isa String
    end
    
    @testset "Auto styles loading" begin
        styles_html = Nova.auto_load_styles()
        @test styles_html isa String
        @test startswith(styles_html, "<style>")
        @test endswith(styles_html, "</style>")
    end
end
