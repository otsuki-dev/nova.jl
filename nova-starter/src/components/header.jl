using ..Nova

function header()
    return """
    <header>
        <div class="logo">
            <a href="/">
            <img
                src="nova-jl-w.svg"
                alt="Nova.jl Logo"
                title="Build fast, efficient web applications with Julia"
            />
            </a>
        </div>
        <nav class="main-nav">
            <ul>
                <li><a href="/">Home</a></li>
                <li><a href="/documentation">Documentation</a></li>
                <li><a href="/templates">Templates</a></li>
            </ul>
        </nav>
    </header>
    """
end

export header
