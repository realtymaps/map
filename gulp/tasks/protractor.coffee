gulp = require('gulp')
spawn = require('child_process').spawn
log = require('gulp-util').log

gulp.task 'protractor', (done) ->
  spawn('npm', ['run', 'protractor'], {stdio: 'inherit'}).on 'close', (code) ->
    log('protractor process exited with code ' + code)
    done(code)
