_ = require 'lodash'
baseObjectKeywords = ['extended', 'included']

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

  @extend: (obj) ->
    for key, value of obj when key not in baseObjectKeywords
      @[key] = value
    obj.extended?.apply(@)
    @

  @include: (obj) ->
    for key, value of obj when key not in baseObjectKeywords
      #Assign properties to the prototype
      @::[key] = value
    obj.included?.apply(@)
    @

module.exports = BaseObject
