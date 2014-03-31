restify = require 'restify'
passport = require 'passport'
config = require './config'
Group = require './api/group'
Authentication = require './authentication'
DatabaseProvider = require './database_provider'

databaseProvider = new DatabaseProvider()

# Set up passport authentication strategy
auth = new Authentication(passport, databaseProvider)


# Create the server with name and version
app = restify.createServer({
    name: 'LunchAPI',
    version: "0.0.1"
})


app.on 'uncaughtException', (res, req, next, err) ->
    console.error err.stack


app.use restify.bodyParser()
app.use restify.queryParser()
app.use passport.initialize()


# Auth routes
app.post '/register', auth.getRegisterRoute()
app.post '/login', auth.getLoginRoute()

# API routes
app.get '/api/hello', auth.authenticate(), (req, res, next) ->
    user = req['user']
    Group.getGroupsByUser(user, databaseProvider)
    .then (groups) ->
        res.send(groups)


# Serve static files if no api file matches
app.get '/.*?', restify.serveStatic
    directory: __dirname + '/../public',
    default: "index.html"

# Start the server at the specified port and ip
app.listen config.server.port, config.server.ip, () ->
    console.log '%s listening at %s', app.name, app.url