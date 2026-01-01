"""
About page - Simple HTML without styling
"""

function handler()
    return """
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>About - Nova.jl</title>
    </head>
    <body>
        <h1>About Nova.jl</h1>
        
        <p>Nova.jl is a minimal web framework focused on:</p>
        
        <ul>
            <li><strong>Performance</strong>: Built on HTTP.jl for maximum speed</li>
            <li><strong>Simplicity</strong>: Convention over configuration</li>
            <li><strong>Developer Experience</strong>: Hot reload, clear errors</li>
            <li><strong>Pure Julia</strong>: No JavaScript tooling required</li>
        </ul>
        
        <h2>Architecture</h2>
        <p>The framework is organized into focused modules:</p>
        <ul>
            <li>Server - HTTP handling and routing</li>
            <li>Rendering - HTML generation</li>
            <li>DevTools - Hot reload system</li>
            <li>Utils - Helper functions</li>
        </ul>
        
        <p><a href="/">← Back to Home</a></p>
    </body>
    </html>
    """
end
