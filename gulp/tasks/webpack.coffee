gulp = require 'gulp'
gWebpack = require 'gulp-webpack'
HtmlWebpackPlugin = require 'html-webpack-plugin'
configFact = require '../../webpack.conf.coffee'
paths = require '../paths'
plumber = require 'gulp-plumber'
_ = require 'lodash'

#end dependencies

conf = configFact(
  output =
    filename: paths.dest.scripts + "/[name].wp.js"
    chunkFilename: paths.dest.scripts + "/[id].wp.js"
  ,
  additionalPlugs = [new HtmlWebpackPlugin template: paths.index]
)

gulp.task 'webpack', ['otherAssets'], ->
  gulp.src [
    paths.assets
    paths.styles
    paths.stylus
    paths.jade
    paths.html
    paths.scripts
  ]
  .pipe plumber()
  .pipe(gWebpack conf)
  .pipe(gulp.dest(paths.dest.root))
