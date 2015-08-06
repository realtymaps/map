gutil = require('gulp-util')

exports.errorHandler = (title) ->
  (err) ->
    gutil.log gutil.colors.red('[' + title + ']'), err.toString()
    @emit 'end'
