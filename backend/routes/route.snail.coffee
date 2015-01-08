Promise = require 'bluebird'
ExpressResponse = require '../utils/util.expressResponse'
config = require '../config/config'
httpStatus = require '../../common/utils/httpStatus'
lobService = require '../services/service.lob.coffee'
escape = require('escape-html');

module.exports =
  quote: (req, res, next) -> Promise.try () ->
    lobService.getPriceQuote(req.user.id, req.body.templateId, req.body)
    .then (price) ->
      next new ExpressResponse(price: price)
    .catch (err) ->
      next new ExpressResponse(alert: msg: "Oops! We couldn't get a price quote for that right now. Please try again
                                            in a few minutes. If the problem continues, please let us know by emailing
                                            #{config.SUPPORT_EMAIL}, and giving us the following error message:
                                            <br/><code>#{escape(err.message)}</code>", httpStatus.INTERNAL_SERVER_ERROR, true)
  send: (req, res, next) -> Promise.try () ->
    lobService.sendSnailMail(req.user.id, req.body.templateId, req.body)
    .then () ->
      next new ExpressResponse(alert: type: 'rm_success', msg: "Success!  Your snail mail will go out in 2-3 business days.")
    .catch (err) ->
      next new ExpressResponse(alert: msg: "Oops! We couldn't send your mailing right now. Please try again
                                            in a few minutes. If the problem continues, please let us know by emailing
                                            #{config.SUPPORT_EMAIL}, and giving us the following error message:
                                            <br/><code>#{escape(err.message)}</code>", httpStatus.INTERNAL_SERVER_ERROR, true)
 