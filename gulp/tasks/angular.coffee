gulp = require 'gulp'
require './scripts'
require './styles'
require './otherAssets'

gulp.task 'angular', gulp.parallel 'styles', 'markup', 'browserify'

gulp.task 'angularWatch', gulp.parallel 'stylesWatch', 'markupWatch', 'browserifyWatch'

gulp.task 'angularAdmin', gulp.parallel 'stylesAdmin', 'markupAdmin', 'browserifyAdmin'

gulp.task 'angularWatchAdmin', gulp.parallel 'stylesWatchAdmin', 'markupWatchAdmin', 'browserifyWatchAdmin'
