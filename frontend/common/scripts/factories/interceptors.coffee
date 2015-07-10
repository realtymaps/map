urlHelpers = require '../utils/util.urlHelpers.coffee'
qs = require 'qs'
httpStatus = require '../../../../common/utils/httpStatus.coffee'
commonConfig = require '../../../../common/config/commonConfig.coffee'
escapeHtml = require 'escape-html'


defaultInterceptorList = ['rmapsLoadingIconInterceptor', 'rmapsAlertInterceptor', 'rmapsRedirectInterceptor']

interceptors =
  rmapsRedirectInterceptor: ($location, $rootScope) ->
    routes = urlHelpers.getRoutes($location)

    'response': (response) ->
      if response.data?.doLogin and $location.path() != '/'+routes.login
        $rootScope.principal?.unsetIdentity()
        $location.url routes.login+'?'+qs.stringify(next: $location.path()+'?'+qs.stringify($location.search()))
      if response.data?.profileIsNeeded
        $location.path routes.profiles
      response

  rmapsAlertInterceptor: ($rootScope, $q, rmapsevents) ->
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
        $rootScope.$emit rmapsevents.alert.spawn, response.data?.alert
      else if error && response.status != 0  # status==0 is weird conditions that we probably don't want the user to see
        alert =
          id: "#{response.status}-#{response.config?.url?.split('?')[0].split('#')[0]}"
          msg: commonConfig.UNEXPECTED_MESSAGE escapeHtml(JSON.stringify(status: defineNull(response.status), data:defineNull(response.data)))
        $rootScope.$emit rmapsevents.alert.spawn, alert
      return response
    'response': handle
    'responseError': (response) -> $q.reject(handle(response, true))
    'requestError': (request) ->
      if request.alerts == false
        # we're explicitly not supposed to show an alert for this request according to the frontend
        return $q.reject(request)
      alert =
        id: "request-#{request.url?.split('?')[0].split('#')[0]}"
        msg: commonConfig.UNEXPECTED_MESSAGE escapeHtml(JSON.stringify(url:defineNull(request.status)))
      $rootScope.$emit rmapsevents.alert.spawn, alert
      $q.reject(request)

  rmapsLoadingIconInterceptor: ($q, rmapsSpinner) ->
    'request': (request) ->
      rmapsSpinner.incrementLoadingCount(request.url)
      request
    'requestError': (rejection) ->
      rmapsSpinner.decrementLoadingCount(rejection.url)
      $q.reject(rejection)
    'response': (response) ->
      rmapsSpinner.decrementLoadingCount(response.config?.url)
      response
    'responseError': (rejection) ->
      rmapsSpinner.decrementLoadingCount(rejection.config?.url)
      $q.reject(rejection)

# take care of loading common interceptors among apps, also provides flexibility for loading different list per app if necessary
module.exports.loadInterceptors = (app, interceptorNames=defaultInterceptorList) ->
  for interceptorName in interceptorNames
    app.factory interceptorName, interceptors[interceptorName]

  app.config ($httpProvider) ->
    for interceptorName in interceptorNames
      $httpProvider.interceptors.push interceptorName
