restify = require 'restify'
passport = require 'passport'
config = require './config'
authentication = require './authentication'


# Set up passport authentication strategy
Authentication = authentication.Authentication
auth = new Authentication(passport)


# Create the server with name and version
app = restify.createServer({
    name: 'LunchAPI',
    version: "0.0.1"
})


app.use restify.bodyParser()
app.use restify.queryParser()
app.use passport.initialize()


# Auth routes
app.post '/register', authentication.routes.register
app.post '/login', authentication.routes.login

# API routes
app.get '/api/.*?', auth.authenticate(), (res, req, next) ->
    console.log 'was AUTH'

# Serve static files if no api file matches
app.get '/.*?', restify.serveStatic
    directory: __dirname + '/../public',
    default: "index.html"

# Start the server at the specified port and ip
app.listen config.server.port, config.server.ip, () ->
    console.log '%s listening at %s', app.name, app.url