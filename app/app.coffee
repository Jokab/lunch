restify = require 'restify'
passport = require 'passport'
config = require './config'
DatabaseProvider = require './database_provider'


# Create the server with name and default API-version
app = restify.createServer({
    name: 'LunchAPI',
    version: "0.0.1"
})

# Set up our default database provider instance
databaseProvider = new DatabaseProvider()

# Export app and databaseProvider, instead of having to pass them to
# every file. Making them circles, yo!
module.exports = {
    app: app
    passport: passport
    databaseProvider: databaseProvider
}

# Include our modules
auth = require './authentication'
api = require './api'

# Set up passport authentication strategy
passport.use auth.auth_helpers.createStrategy()

# Set up plugins
app.use restify.bodyParser()
app.use restify.queryParser()
app.use passport.initialize()

# Auth routes
app.post '/register', auth.routes.register
app.post '/login', auth.routes.login

# API routes
app.get '/api/groups', auth.auth_helpers.authenticate(), api.routes.listGroups


# Serve static files if no api file matches
app.get '/.*?', restify.serveStatic
    directory: __dirname + '/../public',
    default: "index.html"


# Handle uncaught errors
# TODO: handle them..?
app.on 'uncaughtException', (res, req, next, err) ->
    console.error err.stack
    throw err


# Start the server at the specified port and ip
app.listen config.server.port, config.server.ip, () ->
    console.log '%s listening at %s', app.name, app.url
