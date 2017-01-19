mod = require '../module.coffee'

mod.directive 'validationSubmitWatch', (
$validation
$timeout
$parse) ->
  link: (scope, element, attrs) ->
    watchType = $parse(attrs.validationSubmitWatchType)(scope) || '$watchCollection'
    if watchType == 'deep'
      isDeep = true
      watchType - 'watch'

    watch = attrs.validationSubmitWatch
    form = $parse(attrs.validationSubmitForm)(scope)
    cb = $parse(attrs.validationSubmitNotify)(scope)

    scope[watchType] watch, (newVal, oldVal) ->
      return if newVal == oldVal

      $validation.validate(form).success ->
        cb(newVal, oldVal)
    , isDeep
