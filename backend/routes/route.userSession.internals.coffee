_ = require 'lodash'
config = require '../config/config'
userUtils = require '../utils/util.user'

#main entry point to update root user info
safeRootFields = userUtils.safeUserFields.concat([])

['company_id'].forEach ->
  safeRootFields.pop()

safeRootCompanyFields = [
  'address_1'
  'address_2'
  'zip'
  'name'
  'us_state_id'
  'phone'
  'fax'
  'website_url'
]

getIdentity = (req, res) ->
  ret = userUtils.getIdentityFromRequest(req)
  res.json identity: ret


updateCache = (req, res, next) ->
  userUtils.cacheUserValues(req)
  .then () ->
    req.session.saveAsync()
  .then () ->
    getIdentity(req, res, next)


module.exports = {
  getIdentity
  updateCache
  safeRootFields
  safeRootCompanyFields
}
