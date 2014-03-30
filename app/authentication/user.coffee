Q = require 'q'
Transaction = require('pg-transaction')
crypto = require 'crypto'


class User
    HASH_ALGORITHM = 'pbkdf2'
    HASH_ITERATIONS = 100
    HASH_KEY_LEN = 128
    HASH_SALT_LEN = 64


    # Attempts to get the user's api secret from the database.
    # Returns a promise that is resolved with the the token.
    getAPISecretFromDb = (username, dbClient) ->
        defer = Q.defer()

        query = '' +
            ' SELECT api_secret from api_secrets' +
            ' WHERE username = $1'

        dbClient.query query, [username], (err, result) ->
            if err
                defer.reject err
            else if result.rows.length != 1
                defer.reject 'Could not find token in database'
            else
                defer.resolve result.rows[0]["api_secret"]

        defer.promise


    # Tries to get the api secret from the database for the user.
    getAPISecret: () ->
        if @api_secret?
            return Q.resolve(@api_secret)

        dbClient = null
        dbClientDone = null

        @databaseProvider.getClient()
        .then ([client, doneCallback]) ->
            dbClient = client
            dbClientDone = doneCallback
        .then () =>
            getAPISecretFromDb @username, dbClient
        .then (api_secret) ->
            @api_secret = api_secret
        .finally () ->
            dbClientDone?()


    # Returns the user's username.
    getUsername: () ->
        @username


    # Creates a new user instance representing a user in the
    # database.
    constructor: (@username, @databaseProvider) ->
        return


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


    # Creates a random secret key used as a user's secret key.
    createAPISecret = () ->
        hashSum = crypto.createHash('SHA1')
        hashSum.update crypto.randomBytes(128).toString('base64')
        hashSum.digest('hex')

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


    # Creates a new user entry in the database.
    # Returns a promise that is resolved on success.
    insertUserIntoDb = (username, hash, salt, api_secret, dbClient) ->
        defer = Q.defer()
        tx = new Transaction(dbClient)

        tx.on 'error', (err) ->
            console.error 'DBError: ' + err
            console.log err.stack
            defer.reject new Error('Could not insert user into database')

        tx.query '' +
                ' INSERT INTO users (username, password, salt)' +
                ' VALUES ($1, $2, $3)',
            [username, hash, salt]

        tx.query '' +
                ' INSERT INTO api_secrets (username, api_secret)' +
                ' VALUES ($1, $2)',
            [username, api_secret]

        tx.commit () ->
            defer.resolve

        defer.promise


    # Checks a password and salt combination against a hash to see if
    # they match. Returns a promise that is resolved if the password
    # and hash matches.
    verifyPassword = (password, salt, hash) ->
        [algorithm, iterations, keyLen, key] = hash.split ':'
        iterations = parseInt(iterations, 10)
        keyLen = parseInt(keyLen, 10)

        # Hash the provided password with the same algorithm and arguments
        # if the key is the same the passwords match
        createPasswordHash password, salt, algorithm, iterations, keyLen
        .then ([h, s, derivedKey]) ->
            if derivedKey != key
                return Q.reject new Error('Password and hash does not match')
            Q.resolve()

    # Fetches information about a username.
    # Returns a promise resolved with
    # `[username, password, salt]`
    getDetailsByUsername = (username, dbClient) ->
        defer = Q.defer()
        query = '' +
            ' SELECT password, salt FROM users' +
            ' WHERE username = $1'

        dbClient.query query, [username], (err, result) ->
            if err?
                console.error 'DBError: ' + err
                defer.reject new Error('Could not get user info from database')
            else if result.rows.length != 1
                defer.reject new Error('Could not get user info from database')
            else
                row = result.rows[0]
                defer.resolve [username, row["password"], row["salt"]]

        defer.promise


    # Attempts to register a user with the provided username and
    # password. The databaseProvider should be a DatabaseProvider instance.
    # Returns a promise that is resolved on success.
    @register: (username, password, databaseProvider) ->
        dbClient = null
        dbClientDone = null

        databaseProvider.getClient()
        .then ([client, doneCallback]) ->
            dbClient = client
            dbClientDone = doneCallback
        .then () ->
            checkUsernameAvailable(username, dbClient)
        .then () ->
            [createPasswordHash(password), createAPISecret()]
        .spread ([hash, salt], api_secret) ->
            insertUserIntoDb username, hash, salt, api_secret, dbClient
        .finally () ->
            dbClientDone?()


    # Attempts to login a user using username and password.
    # Returns a promise that is resolved with a user instance.
    @login: (username, password, databaseProvider) ->
        dbClient = null
        dbClientDone = null

        databaseProvider.getClient()
        .then ([client, doneCallback]) ->
            dbClient = client
            dbClientDone = doneCallback
            getDetailsByUsername username, dbClient
        .then ([username, hash, salt]) ->
            verifyPassword password, salt, hash
        .then () ->
            new User username, databaseProvider
        .finally () ->
            dbClientDone?()


module.exports = User