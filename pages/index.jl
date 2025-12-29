"""
Home page - Simple HTML without styling
Focus: Core functionality and routing
"""

function handler()
    return """
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Nova.jl - Home</title>
    </head>
    <body>
        <h1>Welcome to Nova.jl</h1>
        <p>A minimal, high-performance web framework for Julia.</p>
        
        <h2>Navigation</h2>
        <ul>
            <li><a href="/">Home</a></li>
            <li><a href="/about">About</a></li>
            <li><a href="/api/hello">API Example</a></li>
        </ul>
        
        <h2>Framework Features</h2>
        <ul>
            <li>File-based routing</li>
            <li>Hot reload in development</li>
            <li>Fast HTTP.jl server</li>
            <li>Minimal overhead</li>
            <li>Pure Julia</li>
        </ul>
        
        <footer>
            <p>Nova.jl v0.0.3 - Built with Julia</p>
        </footer>
    </body>
    </html>
    """
end
