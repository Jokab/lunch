Q = require 'q'
databaseUtil = require '../util/databaseUtil'

deferredQuery = databaseUtil.deferredQuery
callDbMethodUsingDbProvider = databaseUtil.callDbMethodUsingDbProvider

class Group

    getGroupListFromDb = (dbClient) ->
        query = '' +
            ' SELECT groups.name, groups.id FROM groups'

        deferredQuery dbClient, query
        .then (result) ->
            Q.resolve result.rows


    getGroupListByUserFromDb = (username, dbClient) ->
        query = '' +
            ' SELECT groups.name, groups.id FROM groups, users_part_of_group P' +
            ' WHERE P.group_id = groups.id and P.username = $1'

        deferredQuery dbClient, query, [username]
        .then (result) ->
            Q.resolve result.rows


    # Gets all groups currently in the database.
    # Returns a promise, resolved with the result.
    @getGroupList: (databaseProvider) ->
        callDbMethodUsingDbProvider databaseProvider, (dbClient) ->
            getGroupListFromDb(dbClient)


    # Gets all groups that the user is part of.
    # Returns a promise, resolved with the result.
    @getGroupListByUser: (user, databaseProvider) ->
        callDbMethodUsingDbProvider databaseProvider, (dbClient) ->
            getGroupListByUserFromDb(user.getUsername(), dbClient)


module.exports = Group
