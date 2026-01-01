using Nova
using JSON
using Dates
using HTTP

function handler(req)
    try
        # Initialize DB (create table if not exists)
        Nova.DB.execute("CREATE TABLE IF NOT EXISTS visits (id INTEGER PRIMARY KEY, timestamp TEXT)")
        
        # Insert current visit
        ts = string(Dates.now())
        Nova.DB.execute("INSERT INTO visits (timestamp) VALUES (?)", (ts,))
        
        # Query recent visits
        results = Nova.DB.query("SELECT * FROM visits ORDER BY id DESC LIMIT 5")
        
        # Convert results to list
        data = []
        for row in results
            push!(data, Dict("id" => row.id, "timestamp" => row.timestamp))
        end
        
        return HTTP.Response(200, ["Content-Type" => "application/json"], JSON.json(Dict(
            "status" => "success",
            "message" => "Database connection working!",
            "recent_visits" => data
        )))
    catch e
        return HTTP.Response(500, ["Content-Type" => "application/json"], JSON.json(Dict(
            "status" => "error",
            "message" => string(e)
        )))
    end
end
