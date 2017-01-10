gulp = require 'gulp'
require './scripts'
require './styles'
require './otherAssets'

gulp.task 'angular', gulp.parallel 'styles', 'browserify'

gulp.task 'angularAdmin', gulp.parallel 'stylesAdmin', 'browserifyAdmin'

gulp.task 'angularProd', gulp.parallel 'stylesProd', 'browserifyProd'

gulp.task 'angularAdminProd', gulp.parallel 'stylesAdminProd', 'browserifyAdminProd'

gulp.task 'angularWatch', gulp.parallel 'styles', 'stylesWatch', 'browserifyWatch'

gulp.task 'angularWatchAdmin', gulp.parallel 'stylesAdmin', 'stylesWatchAdmin', 'browserifyWatchAdmin'
