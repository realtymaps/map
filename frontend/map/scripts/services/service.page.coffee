###globals _, angular###
app = require '../app.coffee'
frontendRoutes = require '../../../../common/config/routes.frontend.coffee'

### eslint-disable ###
app.run (rmapsPageService) ->
### eslint-enable ###
  # Ensure that rmapsPageService instance is created

app.provider 'rmapsPageService', () ->
  #
  # Provider functionality injected into config() blocks
  #
  defaults =
    title: null,
    meta: {}

  setDefaults: (pageSettings) ->
    angular.extend defaults, pageSettings

  #
  #  Get an instance of rmapsPageService
  #
  $get: ($rootScope, $window, $state, $stickyState, $log, rmapsMapIds, rmapsPrincipalService, rmapsProfilesService) ->
    $log = $log.spawn 'map:rmapsPageService'

    class RmapsPageService

      #
      # Page Defaults
      #
      title: defaults.title
      meta: defaults.meta
      profiles: rmapsProfilesService

      #
      # Mobile Header State
      #

      mobile: {
        custom: false
        modal: false
      }

      showMobileCustomHeader: () ->
        return @mobile?.custom

      showMobileModalHeader: () ->
        return @mobile?.modal || @isModal()

      #
      # Page Type
      #

      pageType: null

      _findParentPageType: () ->
        @pageType = null
        $current = $state.$current

        while $current and @pageType == null
          @pageType = $current.self.pageType if $current.self.pageType
          $current = $current.parent

        $log.debug "State #{$state.$current.self.name} has Page Type #{@pageType}"

      isMap: () ->
        return @pageType == 'map'

      isModal: () ->
        return @pageType == 'modal'

      isPage: () ->
        return @pageType == 'page'

      #
      # Navigation
      #
      historyLength: $window.history.length

      back: () =>
        if $state.current.mobile?.back?
          $log.debug "Mobile back override to state #{$state.current.mobile.back}"
          $state.go $state.current.mobile.back
        else if $window.history.length > @historyLength
          $window.history.back()
        else
          @goToMap()

      goToMap: (params = {}) ->
        params.project_id ?= rmapsProfilesService.currentProfile?.project_id
        if params.project_id?

          # not useful while we do the $window.location page refresh below
          # ## Clear the current map if any
          # rmapsMapIds.incrementMainMap()

          $stickyState.reset('map')
          rmapsProfilesService.updateCurrentProfileByProjectId params.project_id
          .then ->
            # sledgehammer approach
            url = "/map?project_id=#{params.project_id}"
            $window.location.href = url
            #$state.go 'map', params, { reload: true }

        else
          $state.go 'main'

      goToDashboard: () ->
        if rmapsProfilesService.currentProfile?.project_id?
          $state.go 'project', { id: rmapsProfilesService.currentProfile?.project_id }
        else
          $state.go 'main'

      #
      # Accessors
      #

      allowDynamicTitle: false
      hasDynamicTitle: false

      getTitle: () ->
        return @title

      setDynamicTitle: (value) ->
        @title = value if value and @allowDynamicTitle
        @hasDynamicTitle = true

      reset: () ->
        @mobile.custom = false
        @mobile.modal = false
        @title = defaults.title
        @meta = defaults.meta
        @hasDynamicTitle = false

    page = new RmapsPageService

    #
    # Page context available on root scope for templates
    #
    $rootScope.rmapsPageService = page

    #
    # State change listener to reset page data
    #
    $rootScope.$on "$stateChangeStart", (event, toState) ->
      return if event.defaultPrevented

      if toState.url?
        # Reset the Page related data
        page.reset()

        if toState.page
          page.allowDynamicTitle = !!toState.page.dynamicTitle
          page.title = toState.page.title if toState.page.title and !page.allowDynamicTitle
          page.meta = toState.page.meta if toState.page.meta

        if toState.mobile
          page.mobile.modal = toState.mobile.modal

    #
    # State Change Success listener to store page type to avoid repeated evaluation of parent-hierarchy
    #
      ### eslint-disable###
    $rootScope.$on "$stateChangeSuccess", (event, toState) ->
      ### eslint-enable###
      page._findParentPageType()

    return page
