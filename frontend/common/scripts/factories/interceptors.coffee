qs = require 'qs'
httpStatus = require '../../../../common/utils/httpStatus.coffee'
commonConfig = require '../../../../common/config/commonConfig.coffee'
escapeHtml = require 'escape-html'
mod = require '../module.coffee'

defaultInterceptorList = ['rmapsLoadingIconInterceptorFactory', 'rmapsAlertInterceptorFactory', 'rmapsRedirectInterceptorFactory']

interceptors =
  rmapsRedirectInterceptorFactory: ($location, $rootScope, $injector, $log, rmapsUrlHelpersService) ->
    "ngInject"
    $log = $log.spawn "rmapsRedirectInterceptorFactory"
    routes = rmapsUrlHelpersService.getRoutes()

    'response': (response) ->
      if response.data?.doLogin and $location.path() != '/'+routes.login
        if $injector.get('rmapsPrincipalService').isAuthenticated()
          $rootScope.principal?.unsetIdentity()

          # Must use the injector to avoid circular injection issue with $http interceptors and $state
          $log.debug 'Force login redirect due to API do login'
          $injector.get('rmapsMapAuthorizationFactory').forceLoginRedirect()

      if response.data?.profileIsNeeded
        $location.path routes.profiles

      response

  rmapsAlertInterceptorFactory: ($rootScope, $q, rmapsEventConstants) ->
    "ngInject"
    defineNull = (value) ->
      return if typeof value == 'undefined' then null else value
    handle = (response, error=false) ->
      if response.config?.alerts == false
        # we're explicitly not supposed to show an alert for this request according to the frontend
        return response
      if response.data?.alert?
        if !response.data?.alert
          # alert is a falsy value, that means we're explicitly not supposed to show an alert according to the backend
          return response
        # yay!  the backend wants us to show an alert!
        $rootScope.$emit rmapsEventConstants.alert.spawn, response.data?.alert
      else if error && response.status != 0  && response.status != -1 # status==0 is weird conditions that we probably don't want the user to see, -1 is similar (cancelled is one case)
        id = "#{response.status}-#{response.config?.url?.split('?')[0].split('#')[0]}"
        if response.headers('Content-Type')?.toLower() != 'application/json'
          msg = commonConfig.UNEXPECTED_MESSAGE(escapeHtml("Malformed error response; hosting provider may be experiencing problems.  HTTP status: #{response.status}"))
        else
          msg = commonConfig.UNEXPECTED_MESSAGE escapeHtml(JSON.stringify(status: defineNull(response.status), data:defineNull(response.data)))
        $rootScope.$emit(rmapsEventConstants.alert.spawn, {id, msg})
      return response
    response: handle
    responseError: (response) -> $q.reject(handle(response, true))
    requestError: (request) ->
      if request.alerts == false
        # we're explicitly not supposed to show an alert for this request according to the frontend
        return $q.reject(request)
      alert =
        id: "request-#{request.url?.split('?')[0].split('#')[0]}"
        msg: commonConfig.UNEXPECTED_MESSAGE escapeHtml(JSON.stringify(url:defineNull(request.status)))
      $rootScope.$emit rmapsEventConstants.alert.spawn, alert
      $q.reject(request)

  rmapsLoadingIconInterceptorFactory: ($q, rmapsSpinnerService) ->
    "ngInject"
    request: (request) ->
      rmapsSpinnerService.incrementLoadingCount(request.url)
      request
    requestError: (rejection) ->
      rmapsSpinnerService.decrementLoadingCount(rejection.url)
      $q.reject(rejection)
    response: (response) ->
      rmapsSpinnerService.decrementLoadingCount(response.config?.url)
      response
    responseError: (rejection) ->
      rmapsSpinnerService.decrementLoadingCount(rejection.config?.url)
      $q.reject(rejection)
###
take care of loading common interceptors among apps,
also provides flexibility for loading different list per app if necessary
###
for interceptorName in defaultInterceptorList
  mod.factory interceptorName, interceptors[interceptorName]

mod.config ($httpProvider) ->
  for interceptorName in defaultInterceptorList
    $httpProvider.interceptors.push interceptorName
