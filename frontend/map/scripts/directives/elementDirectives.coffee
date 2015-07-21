app = require '../app.coffee'
numeral = require 'numeral'

#http://stackoverflow.com/questions/17063000/ng-model-for-input-type-file
app.directive 'rmapsFileRead', () ->
  scope:
    rmapsFileRead: '='
    rmapsFileReadOnLoad: '='
  link: (scope, element, attrs) ->
    element.on 'change', (changeEvent) ->
      reader = new FileReader

      reader.onload = (loadEvent) ->
        if scope.rmapsFileReadOnLoad? && _.isFunction scope.rmapsFileReadOnLoad
          scope.rmapsFileReadOnLoad(loadEvent)

        scope.$evalAsync ->
          scope.rmapsFileRead = loadEvent.target.result

      reader.readAsDataURL changeEvent.target.files[0]

# could develop this further beyond base64
# reader.onload ->
#     binary = reader.result; // binary data (stored as string), unsafe for most actions
#     base64 = btoa(binary); // base64 data, safer but takes up more memory
# reader.readAsBinaryString(img);

['width', 'height'].forEach (name) ->
  directiveName = "rmapsGet#{name.toInitCaps()}"
  app.directive directiveName, ->
    scope: false
    link: (scope, element, attrs) ->
      obj = scope.$eval(attrs[directiveName])
      max = parseInt attrs["rmapsGetMax#{name.toInitCaps()}"]
      eleType = attrs["rmapsMsgReplace"]
      msg = "element #{name} is > #{max} pixles. element must be smaller."
      if eleType
        msg.replace(/element/g, eleType)
      update = ->
        scope.$evalAsync ->
          obj[name] = element[0]['client' + name.toInitCaps()]
          if obj[name] > max
            obj.errors = if !obj.errors? then [msg] else obj.errors.concat [msg]

      element.on 'change', update
      element.on 'load', update


app.directive 'rmapsGetElement', ->
  scope: false
  link: (scope, element, attrs) ->
    obj = scope.$eval(attrs['rmapsGetElement'])
    elementPropName = attrs['rmapsGetElementName'] or 'element'
    obj[elementPropName] = element
