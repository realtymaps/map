gulp = require 'gulp'

#karma, then mocha
gulp.task 'spec', ['build'], ->
  gulp.start ['frontendSpec','backendSpec','gulpSpec']

gulp.task 'spec_watch', ['spec', 'watch']
