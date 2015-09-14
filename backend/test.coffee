config = require './config/config'

require '../common/extensions/strings'
require './config/promisify'
require './extensions'

logger = require './config/logger'


logger.debug('Start of file.')

foo = ->
  logger.debug('in foo')
  bar = ->
    logger.debug('in bar')
    throw new Error 'this is a demo'
  bar()
setTimeout(
  lol = ->
    logger.debug('in lol')
    foo()
  , 1000)

logger.debug('End of file.')


