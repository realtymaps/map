gulp = require 'gulp'

#karma, then mocha (backendSpec, gulpSpec)
#dependency order is ok because fronendSpec needs build as well so build should happen first
gulp.task 'spec', ['build', 'frontendSpec','backendSpec','gulpSpec']

gulp.task 'spec_watch', ['spec', 'watch']
