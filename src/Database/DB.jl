module DB

using SQLite

export connect, query, execute

# Global connection holder
const _connection = Ref{Union{SQLite.DB, Nothing}}(nothing)

"""
    connect(path::String="nova.db")

Establishes a connection to the SQLite database.
"""
function connect(path::String="nova.db")
    _connection[] = SQLite.DB(path)
    return _connection[]
end

"""
    get_connection()

Returns the active database connection. Auto-connects to "nova.db" if not connected.
"""
function get_connection()
    if isnothing(_connection[])
        @info "Database not connected. Auto-connecting to 'nova.db'..."
        return connect()
    end
    return _connection[]
end

"""
    query(sql::String, params=())

Executes a SQL query and returns the result.
"""
function query(sql::String, params=())
    db = get_connection()
    # SQLite.DBInterface is available via SQLite
    return SQLite.DBInterface.execute(db, sql, params)
end

"""
    execute(sql::String, params=())

Executes a SQL statement (like INSERT, UPDATE, DELETE).
"""
function execute(sql::String, params=())
    db = get_connection()
    SQLite.DBInterface.execute(db, sql, params)
end

end
