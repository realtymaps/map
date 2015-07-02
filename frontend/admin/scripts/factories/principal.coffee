app = require '../app.coffee'
principal = require '../../../common/scripts/factories/principal.coffee'
console.log "#### principal code"
module.exports = app.factory 'rmapsprincipal', principal
