jwt = require 'jwt-simple'
Q = require 'Q'
JWTStrategy = require './passport-jwt'
User = require './user'
config = require './../config'
app = require '../app'


JWT_GLOBAL_SECRET = config.authentication.jwt_secret

# Decodes a user's JWT using the user's secret key.
# Throws an error on failure to decode.
validateJWT = (token, user_secret) ->
    jwt.decode(token, JWT_GLOBAL_SECRET + user_secret)


# Sets up the passport JWT authentication strategy
createStrategy = () ->
    new JWTStrategy ((token, done) =>
        # Quick-fail if no token
        if !token or typeof token isnt "string"
            done('Invalid or no token string', null)

        # First get the value without validating, as we need the
        # user's username to get his/her secret.
        payload = jwt.decode(token, null, true)
        user = new User(payload.username, app.databaseProvider)
        user.getAPISecret()
        .then (api_secret) ->
            # Then, with the user's secret, validate the token
            Q.fcall(validateJWT, token, api_secret)
        .then () ->
            done(null, user)
        .catch (err) ->
            done(err, null)
    )


# Wrapper method for setting up the passport
# middleware to use the jwt strategy.
authenticate = () ->
    app.passport.authenticate('jwt', {
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


module.exports = {
    createStrategy : createStrategy
    authenticate: authenticate
    createUserJWT: createUserJWT
}