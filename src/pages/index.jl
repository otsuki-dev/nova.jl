"""
Home page - Simple HTML without styling
Focus: Core functionality and routing
"""

function handler()
    content = """
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
        <p>Nova.jl v0.0.6 - Built with Julia</p>
    </footer>
    """
    
    return Nova.render(content; auto_styles=false, title="Nova.jl - Home")
end
