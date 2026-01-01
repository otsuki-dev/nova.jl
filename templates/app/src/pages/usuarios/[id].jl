function handler(req, params)
    id = get(params, "id", "unknown")
    return "<h1>User ID: $id</h1>"
end
