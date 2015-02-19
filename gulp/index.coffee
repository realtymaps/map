requireDir = require 'require-dir'

# Require all tasks in gulp/tasks, including subfolders
_ = require 'lodash'

requireDir './tasks', recurse: true
