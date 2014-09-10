#Only include files to prevent empty directories http://stackoverflow.com/questions/23719731/gulp-copying-empty-directories
module.exports = (es) ->
  es.map (file, cb) ->
    if file?.stat?.isFile()
      cb(null, file)
    else
      cb()