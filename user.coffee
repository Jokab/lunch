Q = require 'q'
crypto = require('crypto')


class User
    HASH_ALGORITHM = 'pbkdf2'
    HASH_ITERATIONS = 100
    HASH_KEY_LEN = 128
    HASH_SALT_LEN = 64


    @checkUsernameAvailable = (username, dbClient) =>
        defer = Q.defer()
        dbClient.query 'SELECT COUNT(*) > 0 AS user_exists FROM users' +
            ' WHERE username = $1',
            [username], (err, result) ->
                if err
                    defer.reject err

                if result.rows[0].user_exists
                    defer.reject new Error 'User already exists with that name'
                else
                    defer.resolve()

        defer.promise

    # Hashes a function using a predefined hashing algo.
    # Returns a promise that is resolved with the
    # resulting string that should be stored in the db.
    hashPassword = (password) =>
        salt = crypto.randomBytes(HASH_SALT_LEN).toString('base64')

        Q.nfapply crypto[HASH_ALGORITHM], [password, salt, HASH_ITERATIONS, HASH_KEY_LEN]
        .then (derivedKey) ->
            return HASH_ALGORITHM + ":" +
                HASH_ITERATIONS + ":" +
                HASH_KEY_LEN + ":" +
                salt + ":" +
                derivedKey.toString('base64')


    # Checks a password against a hash to see if they match.
    # Returns a promise.
    verifyPassword = (hash, password) =>
        [algorithm, iterations, keyLen, salt, key] = hash.split ':'
        iterations = parseInt(iterations, 10)
        keyLen = parseInt(keyLen, 10)

        if typeof crypto[algorithm] isnt "function"
            return Q.reject 'Invalid algorithm'

        if typeof iterations isnt "number" or iterations < 0
            return Q.reject 'Invalid iterations'

        if typeof keyLen isnt "number" or keyLen < 0
            return Q.reject 'Invalid keyLen'

        if typeof key isnt "string"
            return Q.reject 'Invalid key'

        if typeof salt isnt "string"
            return Q.reject 'Invalid key'

        Q.nfapply crypto[algorithm], [password, salt, iterations, keyLen]
        .then (derivedKey) ->
            return (derivedKey.toString('base64') == key)


    # Attempts to register a user. Returns a
    # promise.
    @register: (username, password, dbClient) ->
        @checkUsernameAvailable username, dbClient
        .then () ->
            hashPassword password
        .then (hash) ->
            true


module.exports = User