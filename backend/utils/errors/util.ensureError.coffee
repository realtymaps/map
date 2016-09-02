_defaultErrorFactory = (err) ->
  new Error(err)

_defaultErrorTest = (err) ->
  err instanceof Error

ensureError = (err, newErrorFactory=_defaultErrorFactory, errorTest=_defaultErrorTest) ->
  if errorTest(err)
    return err
  else
    return newErrorFactory(err)

ensureErrorFactory = (newErrorFactory, errorTest) ->
  return (err) ->
    ensureError(err, newErrorFactory, errorTest)

module.exports = {
  ensureError
  ensureErrorFactory
}
