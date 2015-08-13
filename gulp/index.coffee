requireDir = require 'require-dir'

# Require all tasks in gulp/tasks, including subfolders
require './globals'
require './tasks/default', recurse: true
