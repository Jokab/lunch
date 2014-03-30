Q = require 'q'
BaseStrategy = require 'passport-strategy'

###
    This strategy requires the client to authenticate the users
    by providing their username and password. In return the client
    will receive a JWT. Each request that is performed as the
    user must provide the JWT as an http header field.

###
class Strategy extends BaseStrategy

    # Initializes the api-secret Strategy.
    #
    # Applications must supply a `verify` callback which accepts a `JWT`
    # field, and then calls the `done` callback supplying a `user`,
    # which should be set to `false` if the JWT is not valid.
    # If an exception occurred, `err` should be set.
    constructor: (options, verify) ->
        super()

        if typeof options is "function"
            verify = options
            options = {}

        if not typeof verify is "function"
            throw new Error('verify must be a function!')

        @name = 'jwt'
        @_verify = verify


    authenticate: (req, options) ->
        # TODO: Token should be fetched from an http header
        token = req.params["token"]

        Q.nfcall(@_verify, token)
        .then (user) =>
            @success(user)
        .catch (err) =>
            console.log "Authfail: " + err
            @fail()


module.exports = Strategy