app = require '../app.coffee'
frontendRoutes = require '../../../../common/config/routes.frontend.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

app.controller 'rmapsUserCtrl', ($scope, $rootScope, $location,
  $http, rmapsevents, rmapsprincipal, rmapsMainOptions, $log) ->
    {profile} = rmapsMainOptions.images.dimensions
    maxImagePixles = profile.width
    imageQuality = profile.quality
    rmapsprincipal.getIdentity().then ->
      user = $rootScope.user
      $http.get(backendRoutes.us_states.root)
      .then (data) ->
        $scope.us_states = data.data

      $http.get(backendRoutes.account_use_types.root)
      .then (data) ->
        $scope.accountUseTypes = data.data

      spawnImageAlert = (msg) ->
        imageAlert =
          type:'rm-info'

        imageAlert.msg = msg
        $rootScope.$broadcast rmapsevents.alert.spawn, imageAlert

      _.extend $scope,
        user: _.extend _.clone($rootScope.user, true),
          submit: ->
            $http.put backendRoutes.userSession.root, @
        maxImagePixles: maxImagePixles
        imageQuality: imageQuality
        imageForm:
          cropBlob: ''
          clearErrors: ->
            $scope.$evalAsync ->
              $scope.imageForm.errors = {}
          toRender: ->
            if @cropBlob.length
              return @cropBlob
            if user.account_image_id?
              return @blob || "/api/session/image"
            "/assets/avatar.svg"
          save: ->
            return spawnImageAlert "No Image to Save." unless @blob?

            if _.keys(@errors).length
              _.each @errors, (e) ->
                spawnImageAlert e
              return

            $http.put backendRoutes.userSession.image, blob: @cropBlob
            delete @cropBlob
            delete @blob


        submit: ->
        ready: true
