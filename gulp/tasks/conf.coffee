gutil = require('gulp-util')

exports.errorHandler = (title) ->
  (err) ->
    gutil.log gutil.colors.red('[' + title + ']'), err.toString()
    @emit 'end'


# Options passed to gulp's underlying watch lib chokidar
# See https://github.com/paulmillr/chokidar
exports.chokidarOpts =
  alwaysStat: true
  read: false
