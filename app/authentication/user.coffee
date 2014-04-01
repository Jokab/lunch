Q = require 'q'
Transaction = require('pg-transaction')
crypto = require 'crypto'
databaseUtil = require '../util/databaseUtil'

deferredQuery = databaseUtil.deferredQuery
callDbMethodUsingDbProvider = databaseUtil.callDbMethodUsingDbProvider


# A class representing a user in the database. Also provides
# various static methods for handling users.
class User
    HASH_ALGORITHM = 'pbkdf2'
    HASH_ITERATIONS = 100
    HASH_KEY_LEN = 128
    HASH_SALT_LEN = 64


    # Attempts to get the user's api secret from the database.
    # Returns a promise that is resolved with the the token.
    getAPISecretFromDb = (username, dbClient) ->
        query = '' +
            ' SELECT api_secret from api_secrets' +
            ' WHERE username = $1'

        deferredQuery dbClient, query, [username]
        .then (result) ->
            if result.rows.length != 1
                Q.reject 'Could not find token in database'
            else
                Q.resolve result.rows[0]["api_secret"]


    # Tries to get the api secret from the database for the user.
    getAPISecret: () ->
        if @api_secret?
            return Q.resolve(@api_secret)

        callDbMethodUsingDbProvider @databaseProvider, (dbClient) =>
            getAPISecretFromDb @username, dbClient
            .then (api_secret) =>
                @api_secret = api_secret


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
        query = '' +
            ' SELECT COUNT(*) > 0 AS user_exists FROM users' +
            ' WHERE username = $1'

        deferredQuery dbClient, query, [username]
        .then (result) ->
            if result.rows[0]["user_exists"]
                Q.reject new Error 'User already exists with that name'
            else
                Q.resolve()


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
        query = '' +
            ' SELECT password, salt FROM users' +
            ' WHERE username = $1'

        deferredQuery dbClient, query, [username]
        .then (result) ->
            if result.rows.length != 1
                Q.reject new Error('Could not get user info from database')
            else
                row = result.rows[0]
                Q.resolve [username, row["password"], row["salt"]]
        .catch () ->
            Q.reject new Error('Could not get user info from database')


    # Attempts to register a user with the provided username and
    # password. The databaseProvider should be a DatabaseProvider instance.
    # Returns a promise that is resolved on success.
    @register: (username, password, databaseProvider) ->
        callDbMethodUsingDbProvider databaseProvider, (dbClient) ->
            checkUsernameAvailable(username, dbClient)
            .then () ->
                [createPasswordHash(password), createAPISecret()]
            .spread ([hash, salt], api_secret) ->
                insertUserIntoDb username, hash, salt, api_secret, dbClient


    # Attempts to login a user using username and password.
    # Returns a promise that is resolved with a user instance.
    @login: (username, password, databaseProvider) ->
        callDbMethodUsingDbProvider databaseProvider, (dbClient) ->
            getDetailsByUsername username, dbClient
            .then ([username, hash, salt]) ->
                verifyPassword password, salt, hash
            .then () ->
                new User username, databaseProvider


module.exports = User
