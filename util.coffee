# Returns a boolean indicating if all the values of
# required is in the paramObj
hasRequiredParameters = (paramObj, required...) =>
    for param in required
        if typeof paramObj[param] is "undefined"
            return false
    true


module.exports = {
    hasRequiredParameters: hasRequiredParameters
}