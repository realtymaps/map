log = require('gulp-util').log

module.exports = (glob, name = 'glob', printAllFiles = false) ->
  log "#{name} FILES: #{glob}" if printAllFiles
  log "#{name} isArray: #{Array.isArray(glob)}"
  log "#{name} array length: #{glob.length}"
  log "type #{name}: #{ typeof glob}"
  log "type #{name}[0]: #{ typeof glob[0]}"
