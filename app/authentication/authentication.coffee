restify = require 'restify'
jwt = require 'jwt-simple'
Q = require 'Q'
JWTStrategy = require './passport-jwt'
routes = require './routes'
User = require './user'
config = require './../config'

# Helper class for setting up authentication
class Authentication

    JWT_GLOBAL_SECRET = config.authentication.jwt_secret

    validateJWT = (token, user_secret) ->
        jwt.decode(token, JWT_GLOBAL_SECRET + user_secret)


    # Sets up the passport JWT authentication strategy
    createStrategy: () ->
        new JWTStrategy ((token, done) =>
            try
                payload = jwt.decode(token, null, true)
                user = new User(payload.username, @databaseProvider)
                user.getAPISecret()
                .then (api_secret) ->
                    Q.fcall(validateJWT, token, api_secret)
                .then () ->
                    done(null, user)
                .done()
            catch err
                done(err, null)
        )

    constructor: (@passport, @databaseProvider) ->
        @passport.use @createStrategy()

    # Wrapper method for setting up the passport
    # middleware to use the jwt strategy.
    authenticate: () ->
        @passport.authenticate('jwt', {
            session: false,
            assignProperty: 'user'
        })


    # Creates a JWT for the provider user.
    # Returns a promise that is resolved with the JWT on success.
    createUserJWT = (user) ->
        user.getAPISecret()
        .then (user_secret) ->
            payload = {
                username: user.getUsername()
            }
            jwt.encode(payload, JWT_GLOBAL_SECRET + user_secret)


    # Returns the login route handler
    getLoginRoute: () ->
        # Create an object for the login handler's this, allowing
        # it to call the `createUserJWT` method above.
        # TODO: Find some better way to handle this
        scope = {
            createUserJWT: createUserJWT,
            databaseProvider: @databaseProvider
        }
        () ->
            routes.login.apply(scope, arguments)


    # Returns the register route handler
    getRegisterRoute: () ->
        scope = {
            databaseProvider: @databaseProvider
        }
        () ->
            routes.register.apply(scope, arguments)


module.exports = Authentication