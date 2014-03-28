Q = require 'q'
crypto = require('crypto')


class User
    HASH_ALGORITHM = 'pbkdf2'
    HASH_ITERATIONS = 100
    HASH_KEY_LEN = 128
    HASH_SALT_LEN = 64

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

    # Creates a random secret key used as a user's secret key.
    createAPISecret = () ->
        hashSum = crypto.createHash('SHA1')
        hashSum.update crypto.randomBytes(128).toString('base64')
        hashSum.digest('hex')

    # Attempts to get the user's api secret from the database.
    # Returns a promise that is resolved with the the token.
    getAPISecretFromDb = (user_id, dbClient) ->
        defer = Q.defer()

        query = '' +
            ' SELECT api_secret from api_secrets' +
            ' WHERE user_id = $1 LIMIT 1'

        dbClient.query query, [user_id], (err, result) ->
            if err
                defer.reject err
            else if result.rows.length != 1
                defer.reject 'Could not find token in database'
            else
                defer.resolve result.rows[0]["api_secret"]

        defer.promise

    # Attempts to insert an api_secret into the database for
    # the user with id user_id.
    # Returns a promise resolved with the api_secret.
    insertAPISecretIntoDb = (user_id, api_secret, dbClient) ->
        defer = Q.defer()

        query = '' +
            ' INSERT INTO api_secrets (user_id, api_secret)' +
            ' VALUES ($1, $2)'

        dbClient.query query, [user_id, api_secret], (err) ->
            if err?
                console.error 'DBError: ' + err
                defer.reject new Error('Could not insert user into database')
            else
                defer.resolve api_secret

        defer.promise

    # Tries to get an api secret from the database for the user, or
    # creates a new entry for the user if none exists.
    getAPISecret = (user_id, dbClient) ->
        getAPISecretFromDb user_id, dbClient
        .catch () ->
            Q(createAPISecret())
            .then (api_secret) ->
                insertAPISecretIntoDb user_id, api_secret, dbClient


    # Hashes a password.
    # Returns a promise that is resolved with and array holding three
    # values;
    # `[hashString, salt, derivedKey]`
    # Where hashString is a combined string on the format of
    # `algorithm + ":" + iterations + ":" + keyLen + ":" + derivedKey`
    # and is meant to be what is inserted as the password in the database.
    createPasswordHash = (password, salt = null, algorithm = HASH_ALGORITHM, iterations = HASH_ITERATIONS, keyLen = HASH_KEY_LEN) ->
        if not salt?
            salt = crypto.randomBytes(HASH_SALT_LEN).toString('base64')

        Q.nfapply crypto[algorithm], [password, salt, iterations, keyLen]
        .then (derivedKey) ->
            derivedKeyB64 = derivedKey.toString('base64')
            return [algorithm + ":" + iterations + ":" + keyLen + ":" + derivedKeyB64,
                    salt,
                    derivedKeyB64]


    # Creates a new user entry in the database.
    # Returns a promise.
    insertUserIntoDb = (username, hash, salt, dbClient) ->
        defer = Q.defer()

        query = '' +
            ' INSERT INTO users (username, password, salt)' +
            ' VALUES ($1, $2, $3)'

        dbClient.query query, [username, hash, salt], (err) ->
            if err?
                console.error 'DBError: ' + err
                defer.reject new Error('Could not insert user into database')
            else
                defer.resolve

        defer.promise


    # Checks a password against a hash to see if they match.
    # Returns a promise that is resolved if the password and
    # hash matches.
    verifyPassword = (password, hash, salt) ->
        [algorithm, iterations, keyLen, key] = hash.split ':'
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
        .then ([h, s, derivedKey]) ->
            if derivedKey != key
                return Q.reject 'Password and hash does not match'
            Q.resolve()

    # Fetches information about a username.
    # Returns a promise resolved with
    # `[user_id, username, password, salt]`
    getUserDetails = (username, dbClient) ->
        defer = Q.defer()

        query = '' +
            ' SELECT user_id, password, salt FROM users' +
            ' WHERE username = $1'

        dbClient.query query, [username], (err, result) ->
            if err?
                console.error 'DBError: ' + err
                defer.reject new Error('Could not get user info from database')
            else if not result.rows.length is 1
                defer.reject new Error('Could not get user info from database')
            else
                row = result.rows[0]
                defer.resolve [row["user_id"], username, row["password"], row["salt"]]

        defer.promise


    # Attempts to register a user with the provided username and
    # password. The databaseProvider should be a DatabaseProvider instance.
    # Returns a promise.
    # TODO: should probably not be static method
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
        .then ([hash, salt]) ->
            insertUserIntoDb username, hash, salt, dbClient
        .finally () ->
            dbClientDone() if dbClientDone?

    # Attempts to login a user.
    # Returns a promise that is resolved with an array holding
    # `[user_id, api_secret]`
    # TODO: should not be static method
    @login: (username, password, databaseProvider) ->
        dbClient = null
        dbClientDone = null

        databaseProvider.getClient()
        .then ([client, doneCallback]) ->
            [dbClient = client, dbClientDone = doneCallback]
            return true
        .then () ->
            getUserDetails username, dbClient
        .then ([user_id, username, hash, salt]) ->
            verifyPassword password, hash, salt
            .then () ->
                getAPISecret user_id, dbClient
            .then (api_secret) ->
                {user_id: user_id, api_secret: api_secret}
        .finally () ->
            dbClientDone() if dbClientDone?

module.exports = User