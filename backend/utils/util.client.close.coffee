logger = require('../config/logger').spawn 'util.client.close'

onEndStream = ({client, stream, where, closeFnName}) ->
  where ?= ''
  closeFnName ?= 'end'

  stream.on 'error', (error) ->
    logger.error "#{where} stream errored, closing client"
    logger.error error
    client[closeFnName]()

  stream.on 'close', () ->
    logger.debug "#{where} stream closed, closing client"
    client[closeFnName]()

  stream


module.exports = {
  onEndStream
}
