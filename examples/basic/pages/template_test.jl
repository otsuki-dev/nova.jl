using Nova

function handler()
    data = Dict(
        "name" => "Nova User",
        "items" => [
            Dict("name" => "Item 1"),
            Dict("name" => "Item 2"),
            Dict("name" => "Item 3")
        ]
    )
    
    template = """
    <div class="container">
        <h1>Hello {{name}}!</h1>
        <p>Here is a list of items:</p>
        <ul>
            {{#items}}
            <li>{{name}}</li>
            {{/items}}
        </ul>
        <p>Rendered with Mustache.jl</p>
    </div>
    """
    
    # Create a temporary template file for testing this example
    # In a real app, this would be a separate .html file
    temp_template_path = joinpath(tempdir(), "nova_test_template.html")
    write(temp_template_path, template)
    
    # Use the new render function that takes a file path
    return render(temp_template_path, data, title="Template Test")
end
