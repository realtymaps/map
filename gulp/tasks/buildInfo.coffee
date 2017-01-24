gulp = require('gulp')
Promise = require 'bluebird'
exec = Promise.promisify(require('child_process').exec)
{log} = require 'gulp-util'

gitRev = null

gulp.task 'gitRev', (done) ->
  Promise.try ->
    if process.env.IS_HEROKU == '1'
      return [process.env.HEROKU_SLUG_COMMIT]
    else
      return exec 'git rev-parse HEAD'
  .then ([rev]) ->
    gitRev = rev.trim()
    if process.env.NODE_ENV != 'production'
      gitRev += '-dev'
    log "git revision:", gitRev
    gitRev
  .catch (err) ->
    log "Could not fetch git revision", err
  .finally ->
    done()

gulp.task 'writeBuildInfo', gulp.series 'gitRev', (done) ->
  require('fs').writeFileSync(
    "#{__dirname}/../../frontend/common/scripts/buildInfo.coffee",
    "window.rmaps_build = git_revision: '#{gitRev}', build_time: #{(new Date()).getTime()}"
  )
  done()
