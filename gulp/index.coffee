requireDir = require 'require-dir'

# Require all tasks in gulp/tasks, including subfolders
_ = require 'lodash'
require '../common/extensions/strings'

requireDir './tasks', recurse: true
