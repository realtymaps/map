gulp = require 'gulp'

#karma, then mocha
gulp.task 'spec', ['frontendSpec','backendSpec','gulpSpec']

gulp.task 'spec_watch', ['spec', 'watch']
