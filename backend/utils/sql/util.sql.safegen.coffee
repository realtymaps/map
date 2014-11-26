status = require '../../../common/utils/httpStatus'

module.exports = (genFn, queryOpts, next) ->
  try
    return genFn queryOpts, next
  catch e
    switch e.name
      when 'SqlTypeError'
        next? status: status.BAD_REQUEST, message: e.message
      else
        next? status: status.INTERNAL_SERVER_ERROR, message: e.message