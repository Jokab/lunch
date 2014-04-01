Q = require 'q'


# Wrapper around `dbClient#query` to provide a promise for the
# database query.
# Returns a promise that is resolved with the result on success.
deferredQuery = (dbClient, query, queryArgs = []) ->
    defer = Q.defer()

    dbClient.query query, queryArgs, (err, result) ->
        if err
            defer.reject err
        else
            defer.resolve result

    defer.promise


# Generic helper method for getting a client from a databaseProvider
# and calling a (db)method with the dbClient as argument.
# Returns a promise for the result of the dbMethod call.
callDbMethodUsingDbProvider = (databaseProvider, dbMethod) ->
    dbClient = null
    dbClientDone = null

    databaseProvider.getClient()
    .then ([client, doneCallback]) ->
        dbClient = client
        dbClientDone = doneCallback
    .then () ->
        if dbMethod?
            Q.when dbMethod(dbClient)
        else
            Q.reject 'no dbMethod'
    .finally () ->
        dbClientDone?()


module.exports = {
    callDbMethodUsingDbProvider: callDbMethodUsingDbProvider
    deferredQuery: deferredQuery
}