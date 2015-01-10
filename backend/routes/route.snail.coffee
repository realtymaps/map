Promise = require 'bluebird'
ExpressResponse = require '../utils/util.expressResponse'
config = require '../config/config'
httpStatus = require '../../common/utils/httpStatus'
lobService = require '../services/service.lob'
filterSummaryService = require '../services/service.properties.filterSummary'
escape = require('escape-html');
pdfUtils = require '../../common/utils/util.pdf'
analyzeValue = require '../../common/utils/util.analyzeValue'


lookupErrorMessage =
  "Oops! We couldn't find the property you've selected.
  That really shouldn't happen; please try again in a few minutes. If the
  problem continues, please let us know by emailing #{config.SUPPORT_EMAIL},
  and giving us the following error message:"
validationErrorMessage = (actionMsg) ->
  "Oops! We couldn't #{actionMsg}.  Please make sure you've
  entered a valid address.  If you're sure everything is correct, please let us know
  by emailing #{config.SUPPORT_EMAIL}.  Here's an error message that might help:"
otherErrorMessage = (actionMsg) ->
  "Oops! We couldn't #{actionMsg} right now. Please try again
  in a few minutes. If the problem continues, please let us know by emailing
  #{config.SUPPORT_EMAIL}, and giving us the following error message:"

getPropertyData = (rm_property_id) -> Promise.try () ->
  filterSummaryService.getSinglePropertySummary(rm_property_id)
  .then (property) ->
    if property
      return property
    return Promise.reject new ExpressResponse(errmsg: 
                                                text: lookupErrorMessage
                                                troubleshooting: "id: #{rm_property_id}",
                                              httpStatus.INTERNAL_SERVER_ERROR)

module.exports =
  quote: (req, res, next) -> Promise.try () ->
    getPropertyData(req.body.rm_property_id)
    .then (property) ->
      lobService.getPriceQuote req.user.id, req.body.style.templateId, _.extend({}, pdfUtils.buildAddresses(property), req.body)
    .then (price) ->
      new ExpressResponse(price: price)
    .catch (err) ->
      if err instanceof ExpressResponse
        return err
      console.error(analyzeValue(err))
      if _.isArray err
        return new ExpressResponse(errmsg:
                                     text: validationErrorMessage("get a price quote for that mailing")
                                     troubleshooting: _.flatten(err, "message").join(" | "),
                                   httpStatus.INTERNAL_SERVER_ERROR)
      new ExpressResponse(errmsg:
                            text: otherErrorMessage("get a price quote for that mailing")
                            troubleshooting: "#{escape(err.message||err)}",
                          httpStatus.INTERNAL_SERVER_ERROR)
    .then (response) ->
      next(response)
  
  send: (req, res, next) -> Promise.try () ->
    getPropertyData(req.body.rm_property_id)
    .then (property) ->
      lobService.sendSnailMail req.user.id, req.body.style.templateId, _.extend({}, pdfUtils.buildAddresses(property), req.body)
    .then () ->
      new ExpressResponse({})
    .catch (err) ->
      if err instanceof ExpressResponse
        return err
      console.error(analyzeValue(err))
      if _.isArray err
        return new ExpressResponse(errmsg:
                                     text: validationErrorMessage("send your mailing")
                                     troubleshooting: _.flatten(err, "message").join(" | "),
                                   httpStatus.INTERNAL_SERVER_ERROR)
      new ExpressResponse(errmsg:
                            text: otherErrorMessage("send your mailing")
                            troubleshooting: "#{escape(err.message||err)}",
                          httpStatus.INTERNAL_SERVER_ERROR)
    .then (response) ->
      next(response)
