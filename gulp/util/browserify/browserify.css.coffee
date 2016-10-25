path = require 'path'
logger = require('../logger').spawn('browserify:css')

processRelativeUrl = (url) ->
  # logger.debug "URL (#{url})"
  if url.match(/[.](woff|woff2|ttf|eot|otf)([?].*)?(#.*)?$/i) and !url.match(/^\/\//)
    r_url = url.replace '@{font-path}', ''
    r_url = "./#{r_url}".replace path.dirname("./#{r_url}"), '/fonts'
    logger.debug "rework_url #{url} -> #{r_url}"
    r_url
  else if url.match(/[.](jpg|jpeg|gif|png|svg|ico)([?].*)?(#.*)?$/i) and !url.match(/^\/\//)
    r_url = "./#{url}".replace path.dirname("./#{url}"), '/assets'
    logger.debug "rework_url #{url} -> #{r_url}"
    r_url
  else
    url

module.exports = {
  rootDir: 'styles'
  processRelativeUrl
  global: true
  minify: false
  debug: true #NOTE does not do sourcemaps ,https://github.com/cheton/browserify-css/issues/42
}
