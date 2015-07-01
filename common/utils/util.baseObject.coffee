_ = require 'lodash'
class BaseObject
  bClass: BaseObject
  base: () ->
    args = _.toArray(arguments)
    # console.log args
    classz = args.shift()
    # console.log classz
    obj = args.shift()
    fnName = args.shift()
    # console.log "fnName: #{fnName}"
    # console.log _.functions classz::
    # console.log _.functions obj
    classz::[fnName].apply(obj, args)

module.exports = BaseObject
