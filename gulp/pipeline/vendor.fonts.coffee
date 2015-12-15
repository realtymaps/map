bowerFilesLoader = require('main-bower-files')

bower = bowerFilesLoader
  filter: /[.](woff|woff2|ttf|eot|otf)$/
  checkExistence: true
  # debugging:true

module.exports = _.flatten([bower])
