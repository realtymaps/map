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
  $get: ($rootScope, $window, $state, $log) ->
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

      #
      # Navigation
      #
      historyLength: $window.history.length

      #
      # Accessors
      #
      setTitle: (value) ->
        @title = value if value

      back: () =>
        if $window.history.length > @historyLength
          $window.history.back()
        else
          $state.go 'map', {}, {reload: true}

      reset: () ->
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
