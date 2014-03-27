restify = require 'restify'
config = require './config'

DatabaseProvider = require './lib/database_provider'
databaseProvider = new DatabaseProvider(config.database)

User = require './user'

util = require './util'
hasRequiredParameters = util.hasRequiredParameters

# Create the server with name and version
server = restify.createServer({
    name: 'LunchAPI',
    version: "0.0.1"
})

# bodyParser lets us read POST data from req.params
server.use restify.bodyParser()


server.post '/register', (req, res, next) ->
    if not hasRequiredParameters req.params, 'username', 'password'
        return next(new restify.MissingParameterError "username and password is required.")

    username = req.params.username
    password = req.params.password

    User.register username, password, databaseProvider
    .then () ->
        res.send("OK")
    .catch (err) ->
        console.log  err
        next(err)


# Serve static files if no api file matches
server.get '/.*?', restify.serveStatic
    directory: './public',
    default: "index.html"


# Start the server at the specified port and ip
server.listen config.server.port, config.server.ip, () ->
    console.log '%s listening at %s', server.name, server.url