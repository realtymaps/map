log = require('gulp-util').log

module.exports = (es, toLog) ->
  es.map (file, cb) ->
    log toLog
    cb()