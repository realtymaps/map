app = require '../app.coffee'

app.run (rmapsPage) ->
  # Ensure that rmapsPage instance is created

app.provider 'rmapsPage', () ->
  #
  # Provider functionality injected into config() blocks
  #
  defaults =
    title: null,
    meta: {}

  setDefaults: (pageSettings) ->
    angular.extend defaults, page

  #  //
  #  // Get an instance of a PageContext factory
  #  //
  $get: ($rootScope, $window, $log) ->
    $log.debug 'rmapsPage.$get'
    class RmapsPage

      #
      # Page Defaults
      #
      title: defaults.title
      meta: defaults.meta

      #
      # Header State
      #
      mobile: {
        modal: false
      }

      back: () =>
        console.log 'rmapsPage.back()'
        $window.history.back()

      reset: () ->
        $log.debug('PageContext reset')
        @mobile.modal = false
        @title = defaults.title
        @meta = defaults.meta

    page = new RmapsPage

    #
    # Page context available on root scope for templates
    #
    $rootScope.rmapsPage = page

    #
    # State change listener to reset page data
    #
    $rootScope.$on "$stateChangeStart", (event, toState) ->
      $log.debug "rmapsPage $stateChangeStart... prevented? #{event.defaultPrevented}"
      return if event.defaultPrevented

      if toState.url
        # Reset the Page related data
        page.reset()

        if toState.page
          page.title = toState.page.title if toState.page.title
          page.meta = toState.page.meta if toState.page.meta

        if toState.mobile
          page.mobile.modal = toState.mobile.modal

    # Initialize the service instance
    page.reset()

    return page
