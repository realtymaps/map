app = require '../app.coffee'

app.config(($provide) ->
  #recommended way of dealing with clean up of angular communication channels
  #http://stackoverflow.com/questions/11252780/whats-the-correct-way-to-communicate-between-controllers-in-angularjs
  $provide.decorator '$rootScope', ($delegate) ->
    Object.defineProperty $delegate.constructor::, '$onRootScope',
      value: (name, listener) ->
        unsubscribe = $delegate.$on(name, listener)
        @$on '$destroy', unsubscribe
        unsubscribe

      enumerable: false

    $delegate
)
.config(($httpProvider) ->
  $httpProvider.useApplyAsync(true)
)
.config(($provide) ->
  # attempting to create a cancelable $http on all its functions
  $provide.decorator '$http', ($delegate, $q) ->
    http = {}
    methods = ['get', 'delete', 'head', 'jsonp']
    dataMethods = ['post', 'put', 'patch']
    objectFields = ['defaults', 'pendingRequests']

    allMethods = methods.concat(dataMethods)
    allMethods.forEach (m) ->
      http[m] = $delegate[m]
    http.root = $delegate

    $delegate = (requestConfig) ->
      canceller = $q.defer()
      angular.extend requestConfig, timeout: canceller.promise
      #eliminates the protocol error and allows the client library to handle the error easily
      #through catch and keeps the callstack traceable
      if !requestConfig? or !requestConfig.url?
        canceller.reject("invalid requestConfig #{JSON.stringify(requestConfig)}")
        return canceller.promise
      promise = http.root(requestConfig)
      #TODO: could override promise with another to return data instead data.data (less annoying)

      promise.cancel = ->
        canceller.resolve()

      promise.catch ->
        #if $q.all rejects a collection of promises then we can cancel the http
        promise.cancel()

      promise.finally ->
        #cleanup
        promise.cancel = angular.noop
        canceller = promise = null

      promise

    #pretty much straight copy paste from angular
    methods.forEach (name) ->
      $delegate[name] = (url, config) ->
        $delegate angular.extend config or {},
          method: name
          url: url

    dataMethods.forEach (name) ->
      $delegate[name] = (url, data, config) ->
        $delegate angular.extend config or {},
          method: name
          url: url
          data: data

    objectFields.forEach (name) ->
      $delegate[name] = http.root[name]

    $delegate
)
.config(($validationProvider, rmapsMainOptions) ->
  {validation} = rmapsMainOptions
  $validationProvider.setErrorHTML (msg) ->
    return "<label class=\"control-label has-error\">" + msg + "</label>"
  _.extend $validationProvider,
    # figure out how to do this without jQuery
    validCallback: (element) ->
      #attempt w/o jQuery
      maybeParent = _.first(element.parentsByClass('form-group', true))
      if maybeParent?
        maybeParent.className = maybeParent.className.replace('has-error', '')

      #expected
      #$(element).parents('.form-group:first').removeClass('has-error')
    invalidCallback: (element) ->
      maybeParent = _.first(element.parentsByClass('form-group', true))
      if maybeParent?
        maybeParent.className += ' has-error'
      #parents('.form-group:first').addClass('has-error')

  expression =
    phone: validation.phone
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

  defaultMsg =
    required:
      error: 'Required!!'
    url:
      error: 'Invlaid Url!'
    optUrl:
      error: 'Invlaid Url!'
    email:
      error: 'Invlaid Email!'
    number:
      error: 'Invlaid Number!'
    optNumber:
      error: 'Invlaid Number!'
    minlength:
      error: 'This should be longer'
    optMinlength:
      error: 'This should be longer'
    maxlength:
      error: 'This should be shorter'
    optMaxlength:
      error: 'This should be shorter'
    phone:
      error: 'Invlaid phone number!'
    optPhone:
      error: 'Invlaid phone number!'
    address:
      error: 'Invalid addess.'
    zipcode:
      error: 'Invalid US zipcode.'

  $validationProvider.setExpression(expression).setDefaultMsg(defaultMsg);
)
