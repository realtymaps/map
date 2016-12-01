_ = require 'lodash'


# utility to check required permissions vs allowed permissions
#   required:
#     parameter specifying what permission(s) the user needs in order to
#     access the given route; can either be a single string, or an object
#     with either "any" or "all" as a key and an array of strings as a value
#   allowed:
#     a map of permission codes to boolean values
checkAllowed = (required, allowed) ->
  if not required
    return true
  if not allowed
    return false

  if typeof(required) is 'string'
    required = {any: [required]}
  granted = false
  if required.any
    # we only need one of the permissions in the array
    granted = _.any required.any, (permission) ->
      allowed[permission]?
  else if required.all
    # we need all the permissions in the array
    granted = _.every required.all, (permission) ->
      allowed[permission]?

  return granted

isPermissionRequired = (toMatch, permissionsToSearch) ->
  if !permissionsToSearch?
    return false

  if typeof(permissionsToSearch) is 'string'
    return toMatch == permissionsToSearch

  if Array.isArray(permissionsToSearch)
    toSearch = permissionsToSearch

  toSearch = toSearch || permissionsToSearch?.any || permissionsToSearch?.all || []

  toSearch.indexOf(toMatch) > -1

module.exports = {
  checkAllowed
  isPermissionRequired
}
