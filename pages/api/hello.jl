"""
API endpoint example - Returns JSON
"""

using HTTP
using JSON

function handler()
    data = Dict(
        "message" => "Hello from Nova.jl API!",
        "framework" => "Nova.jl",
        "version" => "0.0.1",
        "timestamp" => string(now())
    )
    
    # Return raw HTTP response for API endpoints
    return HTTP.Response(
        200,
        ["Content-Type" => "application/json"],
        JSON.json(data)
    )
end
