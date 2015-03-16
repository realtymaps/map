gulp = require 'gulp'
require './otherAssets'
gWebpack = require 'gulp-webpack'
HtmlWebpackPlugin = require 'html-webpack-plugin'
configFact = require '../../webpack.conf.coffee'
paths = require '../paths'
plumber = require 'gulp-plumber'
_ = require 'lodash'
fs = require 'fs'
webpack = require 'webpack'

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

runWebpack = (someConfig) ->
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
  .pipe(gWebpack someConfig)
  .pipe(gulp.dest(paths.dest.root))

gulp.task 'webpack', gulp.parallel 'otherAssets', ->
  runWebpack(conf)

gulp.task 'webpackMock', gulp.parallel 'otherAssets', ->
  runWebpack(mockConf)

gulp.task 'webpackProd', gulp.parallel 'otherAssets', ->
  runWebpack(
    configFact(output, [
      new HtmlWebpackPlugin template: paths.index
      #not sure what the option is to mangle on webpack.. we could post mangle via gulp
      new webpack.optimize.UglifyJsPlugin {
        compress: {
          warnings: false
        }}
    ])
  )


