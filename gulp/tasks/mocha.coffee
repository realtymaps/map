gulp = require 'gulp'
mocha = require 'gulp-mocha'

require 'chai'
require 'should'

runMocha = (files, reporter = 'spec') ->
  gulp.src files, read: false
  .pipe(mocha(reporter: reporter))

gulp.task 'backendSpec', ->
  runMocha ['spec/common/**/*spec*', 'spec/backend/**/*spec*']
  .once 'end', () ->
    # node won't quit automatically because of various event listeners that
    # get registered in the normal running of our app/modules -- our app isn't
    # intended to exit, so this isn't a problem in production.  So we kill
    # things here manually.
    process.exit()
  
gulp.task 'gulpSpec', ->
  runMocha  'spec/gulp/**/*spec*'

gulp.task 'mocha', ['backendSpec']
