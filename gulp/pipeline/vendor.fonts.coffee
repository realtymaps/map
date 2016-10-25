_ = require 'lodash'

module.exports = _.flatten [ 'woff', 'woff2', 'ttf', 'eot', 'otf'].map (ext) -> [
  './node_modules/font-awesome/fonts/*.'
  './node_modules/angular-ui-grid/*.'
  ].map (mod) -> mod + ext
