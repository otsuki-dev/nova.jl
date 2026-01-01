using ..Nova

include("../components/header.jl")

function handler()
    header_html = header()

    return Nova.render(
        """
        $header_html
        <div class='container fade-in'>
            <h1>Documentation</h1>
            <p>Welcome to the Nova.jl documentation page. Below you'll find quick guides and examples to help you build apps with Nova.jl.</p>

            <h2>Getting Started</h2>
            <ol>
                <li>Create files under <code>src/pages/</code> to add routes automatically.</li>
                <li>Put static assets under <code>public/</code>.</li>
                <li>Add global styles in <code>src/styles/</code>.</li>
            </ol>

            <h2>Examples</h2>
            <p>See the <a href="/templates">Templates</a> page for demo applications and interactive examples.</p>
        </div>
        """,
    )
end
