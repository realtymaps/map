auth = require '../../utils/util.auth'

module.exports =
  #note security for this route set is an API_KEY provided to CartoDB
  getByFipsCodeAsFile:
    method: 'get'
  getByFipsCodeAsStream:
    method: 'get'
