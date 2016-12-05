app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

app.config(($provide, $validationProvider) ->
  _removeError = (element) ->
    element.className = element.className.replace(/has\-error/g, '') if element?

  $validationProvider.setErrorHTML (msg) ->
    return "<label class=\"control-label has-error\">#{msg}</label>"

  $provide.decorator '$validation', ($delegate) ->
    # figure out how to do this without jQuery
    $delegate.validCallback = (element) ->
      #attempt w/o jQuery
      element.parentsByClass('form-group', true).forEach (ele) ->
        _removeError ele

    $delegate.invalidCallback = (element) ->
      element.parentsByClass('form-group', true).forEach (ele) ->
        ele.className += ' has-error' if ele?
    $delegate

)
.run ($validation, rmapsMainOptions, $http) ->

  {validation} = rmapsMainOptions

  expression =
    email: validation.email
    password: validation.password
    phone: validation.phone
    realtymapsEmail: validation.realtymapsEmail
    optPhone: (value, scope, element, attrs, param) ->
      return true unless value
      #optional URL
      !!value.match(validation.phone)?.length
    address: validation.address
    zipcode: validation.zipcode.US
    optUrl: (value, scope, element, attrs, param) ->
      return true unless value
      #optional URL
      !!value.match(validation.url)?.length
    optNumber: (value, scope, element, attrs, param) ->
      return true unless value
      #optional URL
      !!value.match(validation.number)?.length
    optMinlength: (value, scope, element, attrs, param) ->
      return true unless value
      value.length >= param;
    optMaxlength: (value, scope, element, attrs, param) ->
      return true unless value
      value.length <= param;
    checkUniqueEmail: (value, scope, element, attrs, param) ->
      console.log "checkUniqueEmail()"
      config =
        alerts: param != 'disableAlert'
      $http.post(backendRoutes.email.isUnique, email: value, config)
    checkValidMlsAgent: (value, scope, element, attrs, param) ->
      $http.post(backendRoutes.mls.activeAgent, scope[param], {alerts: false})



  defaultMsg =
    password:
      error: 'Password does not meet requirements: minimum length 10, at least 1 lowercase, 1 capital, 1 number.'
    required:
      error: 'Required'
    url:
      error: 'Invalid Url'
    optUrl:
      error: 'Invalid Url'
    email:
      error: 'Invalid Email'
    realtymapsEmail:
      error: "Email must be of the '@realtymaps.com' domain"
    checkUniqueEmail:
      error: 'Email must be unique'
    checkValidMlsAgent:
      error: 'MLS ID not found or active.'
    number:
      error: 'Invalid Number'
    optNumber:
      error: 'Invalid Number'
    minlength:
      error: 'This should be longer'
    optMinlength:
      error: 'This should be longer'
    maxlength:
      error: 'This should be shorter'
    optMaxlength:
      error: 'This should be shorter'
    phone:
      error: 'Invalid phone number'
    optPhone:
      error: 'Invalid phone number'
    address:
      error: 'Invalid address'
    zipcode:
      error: 'Invalid US zipcode'

  $validation.setExpression(expression).setDefaultMsg(defaultMsg)
