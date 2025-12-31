using ..Nova

function handler()
    return """
    <!DOCTYPE html>
    <html>
    <head>
        <title>404 - Not Found</title>
        <style>
            body { font-family: sans-serif; text-align: center; padding: 50px; }
            h1 { color: #e74c3c; }
        </style>
    </head>
    <body>
        <h1>Oops! Page Not Found</h1>
        <p>We couldn't find the page you were looking for.</p>
        <p><a href="/">Go back home</a></p>
    </body>
    </html>
    """
end
