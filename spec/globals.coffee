hack = require '../common/utils/webpackHack.coffee'

unless window?
  global.should = hack.hiddenRequire 'should'
  global.expect = hack.hiddenRequire('chai').expect
  global.sinon = hack.hiddenRequire 'sinon'
  global._ = hack.hiddenRequire 'lodash'

#  console.log "should: #{should}"
#  console.log "expect: #{expect}"

require '../common/extensions/strings.coffee' #need explicit file if it is called by webpack (npm supports both)