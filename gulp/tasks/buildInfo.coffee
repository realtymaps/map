gulp = require('gulp')


gulp.task 'writeBuildInfo', (done) ->
  sourcemapSvc = require '../../backend/services/service.sourcemap'
  sourcemapSvc.getGitRev()
  .then (gitRev) ->
    require('fs').writeFile(
      "#{__dirname}/../../frontend/common/scripts/buildInfo.coffee",
      "window.rmaps_build = git_revision: '#{gitRev}', build_time: #{(new Date()).getTime()}", done)
