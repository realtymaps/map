gulp = require 'gulp'
del = require 'del'
paths = require '../../common/config/paths'

gulp.task 'clean', (done) ->
  # done is absolutely needed to let gulp known when this async task is done!!!!!!!
  del [paths.dest.root, '.tmp', '*.log'], done
