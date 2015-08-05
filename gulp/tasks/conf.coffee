gutil = require('gulp-util')

exports.wiredep =
  exclude: [
    /bootstrap.js$/
    /bootstrap-sass-official\/.*\.js/
    /bootstrap\.css/
  ]
  directory: 'bower_components'

exports.errorHandler = (title) ->
  (err) ->
    gutil.log gutil.colors.red('[' + title + ']'), err.toString()
    @emit 'end'
