Promise = require 'bluebird'
analyzeValue = require '../../common/utils/util.analyzeValue'
require '../../backend/config/promisify'

# This error class is private, intended for use within this module only
class PromiseExpectationError extends Error
  constructor: (message, @fulfillment) ->
    @name = "PromiseExpectationError"
    analysis = analyzeValue(@fulfillment)
    @message = "#{message} with #{analysis.type}"
    if analysis.details?
      @message += ": #{analysis.details}"
    if @fulfillment.stack?
      @stack = "#{@name}: #{@message}\n#{@fulfillment.stack}"


module.exports =

  # promiseIt() is a replacement for the 'it()' jasmine function, intended for simplifying promise-based tests.
  # Just like 'it()', this accepts a string description and a handler function; unlike 'it()', this function expects
  # its handler to return either a thenable/promise or an array of thenables/promises.  If the promise (or any one of
  # the promises in the array) is rejected, the done() asyncronous callback is called with the rejection reason
  # (wrapped in an Error if necessary) to signal test failure.  If the promise (or all promises in the array) resolve,
  # the done() asyncronous callback is called to signal sucessful test completion.
  promiseIt: (description, handler) ->
    it description, (done) ->
      Promise.try () ->
        result = handler()
        if (typeof result.then == 'function')
          return result
        else
          return Promise.all(result)
      .then () ->
        done()
      .catch (err) ->
        if err not instanceof Error
          err = new Error(err)
        done(err)

  # the promise returned from this function succeeds if the argument promise resolves (passing on the resolved value), and fails otherwise
  expectResolve: (promise) ->
    Promise.try () ->
      promise
    .catch (err) ->
      throw new PromiseExpectationError("expected promise to be resolved, but was rejected", err)

  # the promise returned from this function fails if the argument promise resolves, and:
  #   if a type is not provided, succeeds on any rejection
  #   if a type is provided, succeeds only on a rejection of that type
  # in either case, on success the rejection error/message is passed on
  expectReject: (promise, type=null) ->
    if type == PromiseExpectationError
      # since PromiseExpectationError isn't being exported, this would be a hard situation to create, but it is possible
      throw new Error("PromiseExpectationError passed as rejection type; this error is for internal use only")

    promise = Promise.try () ->
      promise
    .then (value) ->
      throw new PromiseExpectationError("expected promise to be rejected"+(if type? then " with #{analyzeValue(type).details}" else '')+", but was resolved", value)

    if !type?
      promise.catch (err) ->
        if err instanceof PromiseExpectationError
          # this is an error we created in .then() above, we need to pass it through (re-reject)
          throw err
        else
          return err
    else
      promise.catch type, (err) ->
        return err
      .catch (err) ->
        if err instanceof PromiseExpectationError
          # this is an error we created in .then() above, we need to pass it through (re-reject)
          throw err
        else
          throw new PromiseExpectationError("expected promise to be rejected with #{analyzeValue(type).details}, but was rejected", err)
