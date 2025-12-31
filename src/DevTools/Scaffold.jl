module Scaffold

using UUIDs
using Pkg

export create_app

"""
    create_app(name::String; dir::String=pwd())

Creates a new Nova.jl application with the given name in the specified directory.
"""
function create_app(name::String; dir::String=pwd())
    # Define the target directory
    target_dir = joinpath(dir, name)
    
    if isdir(target_dir)
        error("Directory '$name' already exists in $dir")
    end

    # Locate the template directory
    # Assuming the templates folder is at the root of the package
    # We need to find the package root.
    # If Nova is installed as a package, we can use pkgdir(Nova)
    # But since we are inside the module, we can try to deduce it.
    
    # We need to import Nova to use pkgdir, or assume relative path from this file.
    # This file is in src/DevTools/Scaffold.jl
    # Root is ../../
    
    # However, when installed, we should rely on pkgdir if possible.
    # Let's assume the parent module Nova is available or we can find the path.
    
    # A robust way to find the template path:
    template_path = joinpath(dirname(dirname(@__DIR__)), "templates", "app")
    
    if !isdir(template_path)
        # Fallback for when installed via Pkg and maybe the structure is different?
        # But usually artifacts or just including the folder works.
        # If the user adds the package, the whole repo content is usually there if it's a git add.
        # If it's a registry add, we need to make sure `templates` is included in the tarball.
        # (It is by default unless .pkgignore excludes it)
        error("Template directory not found at $template_path")
    end

    println("Creating new Nova app: $name...")

    # Copy the template
    cp(template_path, target_dir)

    # Update Project.toml
    project_file = joinpath(target_dir, "Project.toml")
    content = read(project_file, String)
    
    new_uuid = string(UUIDs.uuid4())
    
    content = replace(content, "{{NAME}}" => name)
    content = replace(content, "{{UUID}}" => new_uuid)
    
    write(project_file, content)

    println("✔ Application created successfully at $target_dir")
    println("\nNext steps:")
    println("  cd $name")
    println("  julia --project -e 'using Pkg; Pkg.instantiate()'")
    println("  julia --project dev.jl")
end

end
