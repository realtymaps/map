log = require('gulp-util').log

module.exports = (es) ->
  es.map (file, cb) ->
    log file.path
    cb()
