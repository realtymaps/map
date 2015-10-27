path = require '../../../common/config/paths'

log = require('gulp-util').log
globDebug = require('../../debug/glob')

bowerFilesLoader = require('main-bower-files')
bowerPath = 'bower_components/'

bower = bowerFilesLoader
  filter: /[.](jpg|jpeg|gif|png)$/
  checkExistence: true
  overrides:
    "leaflet-search":
      main: [
        "dist/leaflet-search.src.js"
        "dist/leaflet-search.src.css"
        "images/search-icon.png"
        "images/search-icon-mobile.png"
      ]
  #debugging: true

#globDebug bower, 'bower'

pipeline = _.flatten([bower])

#pipe.logToob "Vendor", pipeline
module.exports = pipeline
