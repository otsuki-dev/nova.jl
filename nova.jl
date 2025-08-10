
using HTTP
using Revise

include("src/Nova.jl")
using .Nova

include("pages/index.jl")

HTTP.serve() do req
    if req.target == "/"
        return HTTP.Response(200, handler())
    else
        return HTTP.Response(404, "Oops! Page not found.")
    end
end
