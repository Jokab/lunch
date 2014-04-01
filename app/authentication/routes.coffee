restify = require 'restify'
User = require './user'
routeUtils = require './../util/routeUtils'
app = require '../app'
auth_helpers = require './auth_helpers'

hasRequiredParameters = routeUtils.hasRequiredParameters


module.exports.register = (req, res, next) ->
    if not hasRequiredParameters req.params, 'username', 'password'
        return next(new restify.MissingParameterError "username and password is required.")

    username = req.params.username
    password = req.params.password

    User.register username, password, app.databaseProvider
    .then () ->
        res.send("OK")
        next()
    .catch (err) ->
        console.log err
        next(err)
    .done()


module.exports.login = (req, res, next) ->
    if not hasRequiredParameters req.params, 'username', 'password'
        return next(new restify.MissingParameterError "username and password is required.")

    username = req.params.username
    password = req.params.password

    User.login username, password, app.databaseProvider
    .then (user) =>
        auth_helpers.createUserJWT(user)
    .then (jwt) ->
        res.send(jwt)
        next()
    .catch (err) ->
        console.log err
        next(new restify.InvalidCredentialsError('Username and/or password was incorrect.'))
    .done()
