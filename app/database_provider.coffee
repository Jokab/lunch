Q = require 'q'
pg = require 'pg'
dbConfig = (require './config').database


# Class for providing access to the database
class DatabaseProvider

    # Creates a new DatabaseProvider from the provided config object.
    # The config object should be a dict containing keys and values for
    #   'user', 'database', 'password', 'port', 'host' and 'ssl'
    # as used by pg.connect.
    constructor: (config) ->
        # Set default values
        {@user, @database, @password, @port, @host, @ssl} = dbConfig
        # Override if user provided a config object
        if typeof config is "object"
            {@user, @database, @password, @port, @host, @ssl} = config


    # Returns a promise resolved with an array of [PG database client, done].
    # done is a method that should be called once the client is no longer needed,
    # as specified by pg.
    getClient: () ->
        defer = Q.defer()
        pg.connect {
            user: @user,
            database: @database,
            password: @password,
            port: @port,
            host: @host,
            ssl: @ssl
        }, (err, client, done) ->
            if err
                console.log err
                defer.reject new Error('Could not connect to the database')
            else
                defer.resolve [client, done]
        defer.promise


module.exports = DatabaseProvider
