backEndConfig = require '../../backend/config/config'

browserSync = require 'browser-sync'
gulp = require 'gulp'

#http://www.browsersync.io/docs/gulp/
#http://www.browsersync.io/docs/options/
gulp.task 'browserSync', ['express'], ->
  unless process.env.PORT
    browserSync.init
      files: ['_public/**/*']
      proxy: "localhost:#{config.port}"
      port: 3000
      open: false #disable browser auto open
