baseObjectKeywords = ['extended', 'included']

class BaseObject
  bClass: BaseObject
  base: (args...) ->
    classz = args.shift()
    obj = args.shift()
    fnName = args.shift()
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
