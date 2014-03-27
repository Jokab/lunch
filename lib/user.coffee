Q = require 'q'
crypto = require('crypto')


class User
    HASH_ALGORITHM = 'pbkdf2'
    HASH_ITERATIONS = 100
    HASH_KEY_LEN = 128
    HASH_SALT_LEN = 64
    API_TOKEN_LEN = 128

    # Checks if a username is already in the database.
    # Returns a promise that is resolved if there are no
    # users with the username in the database.
    checkUsernameAvailable = (username, dbClient) =>
        defer = Q.defer()

        query = '' +
            ' SELECT COUNT(*) > 0 AS user_exists FROM users' +
            ' WHERE username = $1'

        dbClient.query query, [username], (err, result) ->
            if err
                defer.reject err
            else if result.rows[0]["user_exists"]
                defer.reject new Error 'User already exists with that name'
            else
                defer.resolve()

        defer.promise

    createAPIToken = () ->
        hashSum = crypto.createHash('sha1')
        hashSum.update crypto.randomBytes(API_TOKEN_LEN).toString('base64')
        hashSum.digest('hex')

    # Hashes a function using a predefined hashing algo.
    # Returns a promise that is resolved with the
    # resulting string that should be stored in the db.
    createPasswordHash = (password, salt = null, algorithm = HASH_ALGORITHM, iterations = HASH_ITERATIONS, keyLen = HASH_KEY_LEN) ->
        if not salt?
            salt = crypto.randomBytes(HASH_SALT_LEN).toString('base64')

        Q.nfapply crypto[algorithm], [password, salt, iterations, keyLen]
        .then (derivedKey) ->
            [algorithm + ":" +
                 iterations + ":" +
                 keyLen + ":" +
                 salt + ":" +
                 derivedKey.toString('base64'),
             derivedKey.toString('base64')]


    # Creates a new user entry in the database.
    # Returns a promise.
    insertUserIntoDb = (username, hash, dbClient) ->
        defer = Q.defer()

        query = '' +
            ' INSERT INTO users (username, password_hash)' +
            ' VALUES ($1, $2)'

        dbClient.query query, [username, hash], (err) ->
            if err?
                defer.reject err
            else
                defer.resolve

        defer.promise


    # Checks a password against a hash to see if they match.
    # Returns a promise that is resolved if the password and
    # hash matches.
    verifyPassword = (hash, password) ->
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
            return Q.reject 'Invalid salt'

        # Hash the provided password with the same algorithm and arguments
        # if the key is the same the passwords match
        createPasswordHash password, salt, algorithm, iterations, keyLen
        .then ([hash, derivedKey]) ->
            if derivedKey != key
                return Q.reject 'Password and hash does not match'
            Q.resolve()


    # Attempts to register a user with the provided username and
    # password. The databaseProvider should be a DatabaseProvider instance.
    # Returns a promise.
    @register: (username, password, databaseProvider) ->
        dbClient = null
        dbClientDone = null

        databaseProvider.getClient()
        .then ([client, doneCallback]) ->
            [dbClient = client, dbClientDone = doneCallback]
            return true
        .then () ->
            checkUsernameAvailable(username, dbClient)
        .then () ->
            createPasswordHash(password)
        .then ([hash]) ->
            insertUserIntoDb username, hash, dbClient
        .finally () ->
            dbClientDone() if dbClientDone?



module.exports = User