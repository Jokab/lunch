jwt = require 'jwt-simple'
JWTStrategy = require './passport-jwt'
config = require './../config'

# Helper class for setting up authentication
class Authentication

    validateJWT = (token) ->
        jwt.decode(token, config.authentication.jwt_secret)


    # Sets up the passport authentication strategy
    createStrategy = () ->
        new JWTStrategy ((token, done) ->
            try
                userData = validateJWT(token)
            catch err
                done(err, null)

            done(null, userData)
        )

    constructor: (@passport) ->
        @passport.use createStrategy()

    # Wrapper method for setting up the passport
    # middleware to use the jwt strategy.
    authenticate: () ->
        @passport.authenticate('jwt', {
            session: false
        })


module.exports = Authentication