bowerFilesLoader = require('main-bower-files')

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

pipeline = _.flatten([bower])

module.exports = pipeline
