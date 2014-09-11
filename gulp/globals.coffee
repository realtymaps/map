_ = require 'lodash'
require '../common/extensions/strings'
Promise = require 'bluebird'
log = require('gulp-util').log

namespace = require('ns2').namespace

global._ = _
global.namespace = namespace


global.namespace "realtymaps"

realtymaps.bang = '!!'
realtymaps.dashes = '--'


#log 'realtymaps : %j', realtymaps