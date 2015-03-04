gulp = require 'gulp'
require './otherAssets'
gWebpack = require 'gulp-webpack'
HtmlWebpackPlugin = require 'html-webpack-plugin'
configFact = require '../../webpack.conf.coffee'
paths = require '../paths'
plumber = require 'gulp-plumber'
_ = require 'lodash'
fs = require 'fs'

mockIndexes = fs.readdirSync(paths.mockIndexes)

#end dependencies
output =
  filename: paths.dest.scripts + "/[name].wp.js"
  chunkFilename: paths.dest.scripts + "/[id].wp.js"

conf = configFact(output, [new HtmlWebpackPlugin template: paths.index])
mockConf = configFact(output, mockIndexes.map (fileName) ->
  new HtmlWebpackPlugin
    template: paths.mockIndexes + '/' + fileName
    filename: "mocks/#{fileName}"
)

gulp.task 'webpack', gulp.series 'otherAssets', ->
  gulp.src [
    paths.assets
    paths.styles
    paths.stylus
    paths.jade
    paths.html
    paths.webpackLibs
    paths.scripts
  ]
  .pipe plumber()
  .pipe(gWebpack conf)
  .pipe(gulp.dest(paths.dest.root))

gulp.task 'webpackMock', gulp.series 'otherAssets', ->
  gulp.src [
    paths.assets
    paths.styles
    paths.stylus
    paths.jade
    paths.html
    paths.scripts
  ]
  .pipe plumber()
  .pipe(gWebpack mockConf)
  .pipe(gulp.dest(paths.dest.root))
