restify = require 'restify'
DatabaseProvider = require './../database_provider'
User = require './user'
util = require './util'

databaseProvider = new DatabaseProvider()
hasRequiredParameters = util.hasRequiredParameters


module.exports.register = (req, res, next) ->
    if not hasRequiredParameters req.params, 'username', 'password'
        return next(new restify.MissingParameterError "username and password is required.")

    username = req.params.username
    password = req.params.password

    User.register username, password, databaseProvider
    .then () ->
        res.send("OK")
    .catch (err) ->
        console.log err
        next(err)


module.exports.login = (req, res, next) ->
    if not hasRequiredParameters req.params, 'username', 'password'
        return next(new restify.MissingParameterError "username and password is required.")

    username = req.params.username
    password = req.params.password

    User.login username, password, databaseProvider
    .then (api_secret) ->
        res.send(api_secret)
    .catch (err) ->
        console.log error
        console.error err.stack
        next(err)