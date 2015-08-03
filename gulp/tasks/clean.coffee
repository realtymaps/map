gulp = require 'gulp'
del = require 'del'
gulp.task 'clean', (done) ->
  # done is absolutely needed to let gulp known when this async task is done!!!!!!!
  del ['_public', '*.log'], done
