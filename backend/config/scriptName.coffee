path = require 'path'

scriptName = path.basename(require.main.filename, '.coffee')
if scriptName not in ['server','jobQueueWorker','queueNeedsWorker']
  scriptName = '__REPL'  # this makes it easier to use the result as keys in a hash

module.exports = scriptName
