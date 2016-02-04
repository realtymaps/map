app = require '../app.coffee'

app.run (rmapsPageService) ->
  # Ensure that rmapsPageService instance is created

app.provider 'rmapsPageService', () ->
  #
  # Provider functionality injected into config() blocks
  #
  defaults =
    title: null,
    meta: {}

  setDefaults: (pageSettings) ->
    angular.extend defaults, page

  #
  #  Get an instance of rmapsPageService
  #
  $get: ($rootScope, $window, $state, $log) ->
    $log = $log.spawn 'map:rmapsPageService'

    class RmapsPage

      #
      # Page Defaults
      #
      title: defaults.title
      meta: defaults.meta

      #
      # Mobile Header State
      #

      mobile: {
        modal: false
      }

      #
      # Page Type
      #

      isMap: () ->
        return $state.current?.pageType == 'map'

      isModal: () ->
        return $state.current?.pageType == 'modal'

      isPage: () ->
        return $state.current?.pageType == 'page'

      #
      # Navigation
      #
      historyLength: $window.history.length

      back: () =>
        if $window.history.length > @historyLength
          $window.history.back()
        else
          $state.go 'map', {}, {reload: true}

      #
      # Accessors
      #

      allowDynamicTitle: false

      setDynamicTitle: (value) ->
        @title = value if value and @allowDynamicTitle

      reset: () ->
        @mobile.modal = false
        @title = defaults.title
        @meta = defaults.meta

    page = new RmapsPage

    #
    # Page context available on root scope for templates
    #
    $rootScope.rmapsPageService = page

    #
    # State change listener to reset page data
    #
    $rootScope.$on "$stateChangeStart", (event, toState) ->
      return if event.defaultPrevented

      if toState.url
        # Reset the Page related data
        page.reset()

        if toState.page
          page.allowDynamicTitle = !!toState.page.dynamicTitle
          page.title = toState.page.title if toState.page.title and !page.allowDynamicTitle
          page.meta = toState.page.meta if toState.page.meta

        if toState.mobile
          page.mobile.modal = toState.mobile.modal

    return page
