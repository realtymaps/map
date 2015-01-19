Promise = require 'bluebird'
ExpressResponse = require '../utils/util.expressResponse'
commonConfig = require '../../common/config/commonConfig'
httpStatus = require '../../common/utils/httpStatus'
lobService = require '../services/service.lob'
detailService = require '../services/service.properties.details'
escape = require('escape-html')
pdfUtils = require '../../common/utils/util.pdf'
analyzeValue = require '../../common/utils/util.analyzeValue'


lookupErrorMessage =
  "Oops! We couldn't find the property you've selected.
  That really shouldn't happen; please try again in a few minutes. If the
  problem continues, please let us know by emailing #{commonConfig.SUPPORT_EMAIL},
  and giving us the following error message:"
validationErrorMessage = (actionMsg) ->
  "Oops! We couldn't #{actionMsg}.  Please make sure you've
  entered a valid address.  If you're sure everything is correct, please let us know
  by emailing #{commonConfig.SUPPORT_EMAIL}.  Here's an error message that might help:"
otherErrorMessage = (actionMsg) ->
  "Oops! We couldn't #{actionMsg} right now. Please try again
  in a few minutes. If the problem continues, please let us know by emailing
  #{commonConfig.SUPPORT_EMAIL}, and giving us the following error message:"

getPropertyData = (rm_property_id) -> Promise.try () ->
  detailService.getDetail({rm_property_id: rm_property_id, columns: 'address'})
  .then (property) ->
    if property
      return property
    return Promise.reject new ExpressResponse
      errmsg: 
        text: lookupErrorMessage
        troubleshooting: "id: #{rm_property_id}",
      httpStatus.INTERNAL_SERVER_ERROR

generateErrorHandler = (actionMsg) ->
  (err) ->
    if err instanceof ExpressResponse
      return err
    console.error(analyzeValue(err))
    if _.isArray err
      return new ExpressResponse
        errmsg:
          text: validationErrorMessage(actionMsg)
          troubleshooting: _.flatten(err, "message").join(" | "),
        httpStatus.INTERNAL_SERVER_ERROR
    new ExpressResponse
      errmsg:
        text: otherErrorMessage(actionMsg)
        troubleshooting: "#{escape(err.message||err)}",
      httpStatus.INTERNAL_SERVER_ERROR

    
module.exports =
  quote: (req, res, next) -> Promise.try () ->
    getPropertyData(req.body.rm_property_id)
    .then (property) ->
      lobService.getPriceQuote req.user.id, req.body.style.templateId, _.extend({}, pdfUtils.buildAddresses(property), req.body)
    .then (price) ->
      new ExpressResponse(price: price)
    .catch generateErrorHandler("get a price quote for that mailing")
    .then (response) ->
      next(response)
  
  send: (req, res, next) -> Promise.try () ->
    getPropertyData(req.body.rm_property_id)
    .then (property) ->
      lobService.sendSnailMail req.user.id, req.body.style.templateId, _.extend({}, pdfUtils.buildAddresses(property), req.body)
    .then () ->
      new ExpressResponse({})
    .catch generateErrorHandler("send your mailing")
    .then (response) ->
      next(response)
