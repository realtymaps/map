app = require '../app.coffee'
numeral = require 'numeral'

#http://stackoverflow.com/questions/17063000/ng-model-for-input-type-file
app.directive 'fileread', ->
  scope: fileread: '='
  link: (scope, element, attributes) ->
    element.bind 'change', (changeEvent) ->
      reader = new FileReader

      reader.onload = (loadEvent) ->
        scope.$apply ->
          scope.fileread = loadEvent.target.result

      reader.readAsDataURL changeEvent.target.files[0]

# could develop this further beyond base64
# reader.onload ->
#     binary = reader.result; // binary data (stored as string), unsafe for most actions
#     base64 = btoa(binary); // base64 data, safer but takes up more memory
# reader.readAsBinaryString(img);
