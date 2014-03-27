restify = require 'restify'
config = require './config'
pg = require 'pg'
Q = require 'q'

getDbClient = () ->
    defer = Q.defer()
    pg.connect {
        user: config.database.user,
        database: config.database.database,
        password: config.database.password,
        port: config.database.port,
        host: config.database.host,
        ssl: config.database.ssl
    }, (err, client, done) ->
        if err
            console.log err
            defer.reject new Error('Could not connect to the database')
        else
            defer.resolve [client, done]

    defer.promise

User = require './user'

util = require './util'
hasRequiredParameters = util.hasRequiredParameters

server = restify.createServer({
    name: 'LunchAPI'
})

# bodyParser lets us read POST data from req.params
server.use restify.bodyParser()

server.get '/test.html', (req, res, next) =>
    res.send {
        status: "OK",
        message: "Hello!"
    }
    next()

server.post '/api/auth/register', (req, res, next) =>
    if not hasRequiredParameters req.params, 'username', 'password'
        return next(new restify.MissingParameterError "username and password is required.")

    username = req.params.username
    password = req.params.password

    getDbClient().then ([dbClient, done]) ->
        User.register(username, password, dbClient)
        .then () ->
            res.send("OK")
        .finally () ->
            done()

    .catch (err) ->
        console.log err
        next(err)

    return

# Serve static files if no api file matches
server.get '/.*?', restify.serveStatic
    directory: './public',
    default: "index.html"


server.listen config.server.port, config.server.ip, () ->
    console.log '%s listening at %s', server.name, server.url