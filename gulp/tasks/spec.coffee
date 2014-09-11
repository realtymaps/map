gulp = require 'gulp'

#karma, then mocha
gulp.task 'spec', ['frontendSpec','backendSpec','gulpSpec']
