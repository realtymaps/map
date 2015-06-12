###
webpack-stream is responsible for defining what files are being processed see

See /gulp/task/webpack and see /gulp/paths.coffee
###
# main app controller
app = require '../app.coffee'
module.exports = app.controller 'rmapsMainCtrl', () ->
