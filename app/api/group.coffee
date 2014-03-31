Q = require 'q'

class Group

    getGroupsByUsernameFromDb = (username, dbClient) ->
        defer = Q.defer()

        query = '' +
            ' SELECT groups.name, groups.id FROM groups, users_part_of_group P' +
            ' WHERE P.group_id = groups.id and P.username = $1'

        dbClient.query query, [username], (err, result) ->
            if err
                defer.reject err
            else
                defer.resolve result.rows

        defer.promise

    @getGroupsByUser: (user, databaseProvider) ->
        dbClient = null
        dbClientDone = null

        databaseProvider.getClient()
        .then ([client, doneCallback]) ->
            dbClient = client
            dbClientDone = doneCallback
        .then () ->
            getGroupsByUsernameFromDb user.getUsername(), dbClient
        .finally () ->
            dbClientDone?()

module.exports = Group
