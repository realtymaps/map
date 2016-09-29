_ = require 'lodash'
debug =  require 'debug'
debug = debug('gulp:index')
if !_.fromPairs
  _.fromPairs = _.zipObject
# append ./node_modules to our path for this process
#shamelessly copied from gulp-shell
#https://github.com/sun-zheng-an/gulp-shell/blob/825a24c214ce91027d535ca767df2cfe8745f1a3/index.js#L33-L36
path = require 'path'
pathToBin = path.join(process.cwd(), 'node_modules', '.bin')
pathName = if /^win/.test(process.platform) then 'Path' else 'PATH'
newPath = pathToBin + path.delimiter + process.env[pathName]

debug pathName
debug newPath
_.extend(process.env, _.fromPairs([[pathName, newPath]]))

# console.log process.env

# Require all tasks in gulp/tasks, including subfolders
require './globals'
require './tasks/default', recurse: true
