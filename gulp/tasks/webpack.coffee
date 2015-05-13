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

#console.log "#### paths: " + JSON.stringify(paths)
mockIndexes = fs.readdirSync(paths.rmap.mockIndexes)

#end dependencies
output =
  filename: paths.dest.scripts + "/[name].wp.js"
  chunkFilename: paths.dest.scripts + "/[id].wp.js"

conf = configFact(output, [new HtmlWebpackPlugin template: paths.rmap.index])
mockConf = configFact(output, mockIndexes.map (fileName) ->
  new HtmlWebpackPlugin
    template: paths.mockIndexes + '/' + fileName
    filename: "mocks/#{fileName}"
)
prodConf = configFact(output, [
  new HtmlWebpackPlugin template: paths.rmap.index
  #not sure what the option is to mangle on webpack.. we could post mangle via gulp
  new webpack.optimize.UglifyJsPlugin {
    compress: {
      warnings: false
    }}
])
adminConf = configFact(output, [
  new HtmlWebpackPlugin
    template: paths.admin.index
    filename: "admin/index.html"
  #not sure what the option is to mangle on webpack.. we could post mangle via gulp
  new webpack.optimize.UglifyJsPlugin {
    compress: {
      warnings: false
    }}
])

runWebpack = (someConfig, app='rmap') ->
  gulp.src [
    paths[app].assets
    paths[app].styles
    paths[app].stylus
    paths[app].jade
    paths[app].html
    paths[app].webpackLibs
    paths[app].scripts
  ]
  .pipe plumber()
  .pipe(gWebpack someConfig)
  .pipe(gulp.dest(paths.dest.root))

gulp.task 'webpack', gulp.parallel 'otherAssets', ->
  console.log "#### running regular webpack"
  runWebpack(conf)

gulp.task 'webpackMock', gulp.parallel 'otherAssets', ->
  console.log "#### running webpackMock"
  runWebpack(mockConf)

gulp.task 'webpackProd', gulp.parallel 'otherAssets', ->
  console.log "#### running webpackProd"
  runWebpack(prodConf)

gulp.task 'webpackAdmin', gulp.parallel 'otherAssets', ->
  console.log "#### running webpackAdmin"
  runWebpack(adminConf, 'admin')
