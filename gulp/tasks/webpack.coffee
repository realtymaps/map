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

mockIndexes = fs.readdirSync(paths.rmap.mockIndexes)

# outputs
output =
  filename: paths.dest.scripts + "/[name].wp.js"
  chunkFilename: paths.dest.scripts + "/[id].wp.js"

outputAdmin =
  filename: paths.dest.scripts + "/admin.wp.js"
  chunkFilename: paths.dest.scripts + "/adminChunk.wp.js"

# webpack confs per each environment & app
conf = configFact(output, [new HtmlWebpackPlugin
  template: paths.rmap.index
  filename: "rmap.html"
])
mockConf = configFact(output, mockIndexes.map (fileName) ->
  new HtmlWebpackPlugin
    template: paths.mockIndexes + '/' + fileName
    filename: "mocks/#{fileName}"
)
prodConf = configFact(output, [
  new HtmlWebpackPlugin
    template: paths.rmap.index
    filename: "rmap.html"
  #not sure what the option is to mangle on webpack.. we could post mangle via gulp
  new webpack.optimize.UglifyJsPlugin {
    compress: {
      warnings: false
    }}
], '!')
adminConf = configFact(outputAdmin, [
  new HtmlWebpackPlugin
    template: paths.admin.index
    filename: "admin.html"
  #not sure what the option is to mangle on webpack.. we could post mangle via gulp
  new webpack.optimize.UglifyJsPlugin {
    compress: {
      warnings: false
    }}
])

# webpack task mgmt
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
  runWebpack(conf)

gulp.task 'webpackMock', gulp.parallel 'otherAssets', ->
  runWebpack(mockConf)

gulp.task 'webpackProd', gulp.parallel 'otherAssets', ->
  runWebpack(
    prodConf
    delete prodConfig.devtool
  )

gulp.task 'webpackAdmin', gulp.parallel 'otherAssets', ->
  runWebpack(adminConf, 'admin')

# gulp.task 'webpackProd', gulp.parallel 'otherAssets', ->
# <<<<<<< HEAD
#   runWebpack(prodConf)

# gulp.task 'webpackAdmin', gulp.parallel 'otherAssets', ->
#   runWebpack(adminConf, 'admin')
# =======
#   runWebpack(
#     prodConfig = configFact(output, [
#       new HtmlWebpackPlugin template: paths.index
#       #not sure what the option is to mangle on webpack.. we could post mangle via gulp
#       new webpack.optimize.UglifyJsPlugin {
#         compress: {
#           warnings: false
#         }}
#     ], '!')
#     delete prodConfig.devtool
#   )
# >>>>>>> da3d5fe04ab1a8d75d5be5a650a702e21b0ccb01
