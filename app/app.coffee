restify = require 'restify'
config = require './config'
routes = require './routes'

# Create the server with name and version
app = restify.createServer({
    name: 'LunchAPI',
    version: "0.0.1"
})

# bodyParser lets us read POST data from req.params
app.use restify.bodyParser()

# Auth routes
app.post '/register', routes.auth.register
app.post '/login', routes.auth.login

# Serve static files if no api file matches
app.get '/.*?', restify.serveStatic
    directory: __dirname + '/../public',
    default: "index.html"

# Start the server at the specified port and ip
app.listen config.server.port, config.server.ip, () ->
    console.log '%s listening at %s', app.name, app.url