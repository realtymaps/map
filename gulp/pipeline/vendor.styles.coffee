bowerFilesLoader = require('main-bower-files')

bower = bowerFilesLoader
  filter: /[.]css$/
  checkExistence: true
#  debugging:true


module.exports = _.flatten([bower])
