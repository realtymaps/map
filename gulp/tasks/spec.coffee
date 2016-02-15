gulp = require 'gulp'

require './angular'
require './otherAssets'
require './karma'
require './mocha'
open = require 'open'

gulp.task 'spec', gulp.series gulp.parallel('commonSpec', 'backendSpec', 'frontendSpec'), 'gulpSpec'

gulp.task 'rebuildSpec', gulp.series(
  gulp.parallel('commonSpec', 'backendSpec')
  , gulp.parallel('otherAssets', 'browserifyAll')
  , 'gulpSpec', 'frontendSpec', () -> process.exit(0))

gulp.task 'rspec', gulp.series 'rebuildSpec'

#front end coverage
gulp.task 'openCoverage', (done) ->
  open 'http://localhost:8085/coverage/application/index.html', 'Google Chrome', done

gulp.task 'rcoverage', gulp.series 'vendor', 'frontendCoverageSpec', 'openCoverage'
