"""
    Utils.ErrorHandler

Module for robust error handling, logging, and custom error pages.
Provides structured error responses with clear messages and HTML pages.
"""

module ErrorHandler

using Dates
using HTTP

export NovaException, NotFoundError, ValidationError, ServerError
export handle_error, get_error_page, format_error_message, log_error

# ============================================================================
# Custom Exception Types
# ============================================================================

"""
    NovaException <: Exception

Base exception type for all Nova.jl errors.
"""
abstract type NovaException <: Exception end

"""
    NotFoundError(message::String) <: NovaException

Exception raised when a requested resource is not found (404).
"""
struct NotFoundError <: NovaException
    message::String
end
Base.show(io::IO, e::NotFoundError) = print(io, "NotFoundError: $(e.message)")

"""
    ValidationError(field::String, message::String) <: NovaException

Exception raised when input validation fails (400).
"""
struct ValidationError <: NovaException
    field::String
    message::String
end
Base.show(io::IO, e::ValidationError) = print(io, "ValidationError in '$(e.field)': $(e.message)")

"""
    ServerError(message::String, details::Union{String, Nothing}=nothing) <: NovaException

Exception raised for unexpected server errors (500).
"""
struct ServerError <: NovaException
    message::String
    details::Union{String, Nothing}
end
Base.show(io::IO, e::ServerError) = print(io, "ServerError: $(e.message)")

# ============================================================================
# Error Logging
# ============================================================================

const ERROR_LOG = Ref{Union{IOStream, Nothing}}(nothing)
const ERROR_BUFFER = Ref{Vector{String}}(String[])

"""
    init_error_log(filepath::String)

Initialize error logging to a file.
"""
function init_error_log(filepath::String)
    if ERROR_LOG[] !== nothing
        close(ERROR_LOG[])
    end
    ERROR_LOG[] = open(filepath, "a")
    return nothing
end

"""
    log_error(exception::Exception, request::Union{HTTP.Request, Nothing}=nothing; context::Dict=Dict())

Log an error with timestamp, context, and request info.
"""
function log_error(exception::Exception, request::Union{HTTP.Request, Nothing}=nothing; context::Dict=Dict())
    timestamp = Dates.now()
    error_msg = format_error_message(exception, request; context=context)
    
    # Print to stderr
    @error error_msg
    
    # Write to log file if configured
    if ERROR_LOG[] !== nothing
        write(ERROR_LOG[], "[$timestamp] $error_msg\n")
        flush(ERROR_LOG[])
    end
    
    # Store in buffer for dev server display
    push!(ERROR_BUFFER[], "$timestamp - $error_msg")
    
    # Keep buffer size reasonable
    if length(ERROR_BUFFER[]) > 100
        popfirst!(ERROR_BUFFER[])
    end
end

"""
    format_error_message(exception::Exception, request::Union{HTTP.Request, Nothing}=nothing; context::Dict=Dict())::String

Format error with all available context for logging.
"""
function format_error_message(exception::Exception, request::Union{HTTP.Request, Nothing}=nothing; context::Dict=Dict())::String
    exception_name = String(nameof(typeof(exception)))
    lines = String["Error: $exception_name"]
    
    if isa(exception, NovaException)
        push!(lines, "Message: $(exception.message)")
        if isa(exception, ValidationError)
            push!(lines, "Field: $(exception.field)")
        elseif isa(exception, ServerError) && exception.details !== nothing
            push!(lines, "Details: $(exception.details)")
        end
    else
        push!(lines, "Message: $(exception.msg)")
        push!(lines, "Type: $(typeof(exception))")
    end
    
    if request !== nothing
        push!(lines, "Method: $(request.method)")
        push!(lines, "Path: $(request.target)")
    end
    
    if !isempty(context)
        push!(lines, "Context: $(context)")
    end
    
    return join(lines, " | ")
end

# ============================================================================
# Error Response Pages
# ============================================================================

"""
    get_error_page(status::Int, exception::Exception; dev_mode::Bool=false)::String

Get HTML error page for the given status code and exception.
"""
function get_error_page(status::Int, exception::Exception; dev_mode::Bool=false)::String
    if status == 404
        return get_404_page(exception)
    elseif status == 400
        return get_400_page(exception)
    elseif status == 500
        return get_500_page(exception; dev_mode=dev_mode)
    else
        return get_generic_error_page(status, exception)
    end
end

"""
    get_404_page(exception::Exception)::String

Generate 404 error page.
"""
function get_404_page(exception::Exception)::String
    return """
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>404 - Page Not Found</title>
        <style>
            body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; 
                   background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
                   margin: 0; padding: 0; min-height: 100vh; 
                   display: flex; align-items: center; justify-content: center; }
            .container { background: white; padding: 40px; border-radius: 8px; 
                         box-shadow: 0 10px 25px rgba(0,0,0,0.2); max-width: 500px; }
            h1 { margin: 0 0 10px 0; color: #667eea; font-size: 48px; }
            .code { color: #999; font-size: 14px; margin-bottom: 20px; }
            p { color: #666; line-height: 1.6; }
            a { color: #667eea; text-decoration: none; font-weight: 500; }
            a:hover { text-decoration: underline; }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>404</h1>
            <div class="code">Not Found</div>
            <p>Sorry, the page you're looking for doesn't exist.</p>
            <p><a href="/">← Back to Home</a></p>
        </div>
    </body>
    </html>
    """
end

"""
    get_400_page(exception::Exception)::String

Generate 400 Bad Request error page.
"""
function get_400_page(exception::Exception)::String
    error_detail = isa(exception, ValidationError) ? 
        "Field: <strong>$(exception.field)</strong><br>Issue: $(exception.message)" :
        "Invalid request format or missing required fields."
    
    return """
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>400 - Bad Request</title>
        <style>
            body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; 
                   background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%); 
                   margin: 0; padding: 0; min-height: 100vh; 
                   display: flex; align-items: center; justify-content: center; }
            .container { background: white; padding: 40px; border-radius: 8px; 
                         box-shadow: 0 10px 25px rgba(0,0,0,0.2); max-width: 500px; }
            h1 { margin: 0 0 10px 0; color: #f5576c; font-size: 48px; }
            .code { color: #999; font-size: 14px; margin-bottom: 20px; }
            .error-detail { background: #fff3cd; border-left: 4px solid #ffc107; 
                           padding: 12px; margin: 15px 0; border-radius: 4px; font-size: 14px; }
            p { color: #666; line-height: 1.6; }
            a { color: #f5576c; text-decoration: none; font-weight: 500; }
            a:hover { text-decoration: underline; }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>400</h1>
            <div class="code">Bad Request</div>
            <div class="error-detail">
                $error_detail
            </div>
            <p><a href="/">← Back to Home</a></p>
        </div>
    </body>
    </html>
    """
end

"""
    get_500_page(exception::Exception; dev_mode::Bool=false)::String

Generate 500 Server Error page. Shows stack trace in dev mode.
"""
function get_500_page(exception::Exception; dev_mode::Bool=false)::String
    error_msg = isa(exception, ServerError) ? exception.message : "An unexpected error occurred"
    
    stack_trace = dev_mode ? """
        <div class="stack-trace">
            <h3>Stack Trace (Dev Mode):</h3>
            <pre>$(sprint(showerror, exception))</pre>
        </div>
    """ : ""
    
    return """
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>500 - Server Error</title>
        <style>
            body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; 
                   background: linear-gradient(135deg, #eb3349 0%, #f45c43 100%); 
                   margin: 0; padding: 0; min-height: 100vh; 
                   display: flex; align-items: center; justify-content: center; }
            .container { background: white; padding: 40px; border-radius: 8px; 
                         box-shadow: 0 10px 25px rgba(0,0,0,0.2); max-width: 600px; }
            h1 { margin: 0 0 10px 0; color: #eb3349; font-size: 48px; }
            .code { color: #999; font-size: 14px; margin-bottom: 20px; }
            .error-msg { background: #f8d7da; border-left: 4px solid #f5576c; 
                        padding: 12px; margin: 15px 0; border-radius: 4px; }
            .stack-trace { background: #f5f5f5; padding: 15px; border-radius: 4px; 
                          margin-top: 20px; overflow-x: auto; }
            .stack-trace pre { margin: 0; font-size: 12px; color: #333; }
            p { color: #666; line-height: 1.6; }
            a { color: #eb3349; text-decoration: none; font-weight: 500; }
            a:hover { text-decoration: underline; }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>500</h1>
            <div class="code">Internal Server Error</div>
            <div class="error-msg">
                $error_msg
            </div>
            $stack_trace
            <p><a href="/">← Back to Home</a></p>
        </div>
    </body>
    </html>
    """
end

"""
    get_generic_error_page(status::Int, exception::Exception)::String

Generate generic error page for other status codes.
"""
function get_generic_error_page(status::Int, exception::Exception)::String
    return """
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>$status - Error</title>
        <style>
            body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; 
                   background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
                   margin: 0; padding: 0; min-height: 100vh; 
                   display: flex; align-items: center; justify-content: center; }
            .container { background: white; padding: 40px; border-radius: 8px; 
                         box-shadow: 0 10px 25px rgba(0,0,0,0.2); max-width: 500px; }
            h1 { margin: 0 0 10px 0; color: #667eea; font-size: 48px; }
            p { color: #666; line-height: 1.6; }
            a { color: #667eea; text-decoration: none; font-weight: 500; }
            a:hover { text-decoration: underline; }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>$status</h1>
            <p>An error occurred while processing your request.</p>
            <p><a href="/">← Back to Home</a></p>
        </div>
    </body>
    </html>
    """
end

"""
    handle_error(exception::Exception, status::Int=500; request::Union{HTTP.Request, Nothing}=nothing, dev_mode::Bool=false)::HTTP.Response

Convert an exception to an HTTP response with appropriate status and HTML error page.
"""
function handle_error(exception::Exception, status::Int=500; request::Union{HTTP.Request, Nothing}=nothing, dev_mode::Bool=false)::HTTP.Response
    # Log the error
    log_error(exception, request)
    
    # Determine status code based on exception type
    if isa(exception, NotFoundError)
        status = 404
    elseif isa(exception, ValidationError)
        status = 400
    elseif isa(exception, ServerError)
        status = 500
    end
    
    # Get error page HTML
    error_page = get_error_page(status, exception; dev_mode=dev_mode)
    
    # Return HTTP response
    return HTTP.Response(status, ["Content-Type" => "text/html; charset=utf-8"], error_page)
end

end # module ErrorHandler
