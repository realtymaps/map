app = require '../app.coffee'
numeral = require 'numeral'
_ = require 'lodash'


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
  ['client', 'natural'].forEach (heightType) ->
    directiveName = "rmapsGet#{heightType.toInitCaps()}#{name.toInitCaps()}"
    app.directive directiveName, ->
      scope: false
      link: (scope, element, attrs) ->
        prop = heightType + name.toInitCaps()
        obj = scope.$eval(attrs[directiveName])

        attrName = "rmapsGetMax#{heightType.toInitCaps()}#{name.toInitCaps()}"
        if attrs[attrName]?
          max = parseInt attrs[attrName]

        eleType = attrs['rmapsMsgReplace']

        msg = "element #{prop} is > #{max} pixles. element must be smaller."

        if eleType?
          msg.replace(/element/g, eleType)

        update = ->
          scope.$evalAsync ->
            obj[prop] = element[0][prop]

            if max?
              if obj[prop] > max
                if !obj.errors?
                  obj.errors = {}
                return obj.errors[prop] = msg
              else
                if obj.errors?[prop]
                  delete obj.errors[prop]

        element.on 'change', update
        element.on 'load', update



app.directive 'rmapsGetElement', ->
  scope: false
  link: (scope, element, attrs) ->
    elementName = attrs['rmapsGetElement']
    scope[elementName] = element

# Eventually this may be added to angular. Example from https://groups.google.com/forum/#!msg/angular/lczCSTPMup0/qj1uMqYYdloJ
app.directive 'rmapsAutofocus', ($timeout) ->
  link: (scope, element, attrs) ->
    scope.$watch attrs.rmapsAutofocus, ((val) ->
      if angular.isDefined(val) and val
        $timeout ->
          element[0].focus()
        , 250
    ), true

# solution based on: https://github.com/angular/angular.js/issues/339
app.directive 'embedSrc', ->
  restrict: 'A',
  link: (scope, element, attrs) ->
    current = element
    scope.$watch( () ->
      return attrs.embedSrc
    , () ->
      clone = element.clone().attr 'src', attrs.embedSrc, 'class', '.pdf-preview-letter'
      current.replaceWith clone
      current = clone
    )
