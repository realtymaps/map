_ = require 'lodash'
app = require '../app.coffee'


app.service 'rmapsUserGroupsService', ($http, $q) ->

  save = (userEntity, newPerms, oldPerms) ->
    if newPerms == oldPerms
      return

    permResource = userEntity.all('groups')

    removals = _.difference(oldPerms, newPerms)
    additions = _.difference(newPerms, oldPerms).map (perms) ->
      group_id: perms.id
      user_id: userEntity.id

    removalPromise = $q.map removals, (r) ->
      permResource.doDELETE(r.id)

    addPromise = permResource.doPOST(additions)

    $q.all [removalPromise, addPromise]


  return {
    save
  }
