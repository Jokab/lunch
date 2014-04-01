app = require '../app'

Group = require './group'


module.exports.listGroups = (req, res, next) ->
    if req.params["onlyMine"]?
        user = req['user']
        listPromise = Group.getGroupListByUser(user, app.databaseProvider)
    else
        listPromise = Group.getGroupList(app.databaseProvider)


    listPromise
    .then (groups) ->
        res.send(groups)
        next()
    .catch (err) ->
        next(err)