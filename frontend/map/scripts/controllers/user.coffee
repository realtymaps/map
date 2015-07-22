app = require '../app.coffee'
frontendRoutes = require '../../../../common/config/routes.frontend.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

app.controller 'rmapsUserCtrl', ($scope, $rootScope, $location, $http, rmapsevents, rmapsprincipal) ->
  maxImagePixles = 200
  rmapsprincipal.getIdentity().then ->
    user = $rootScope.user
    $http.get(backendRoutes.us_states.root)
    .then (data) ->
      $scope.us_states = data.data

    spawnImageAlert = (msg) ->
      imageAlert =
        type:'rm-info'

      imageAlert.msg = msg
      $rootScope.$broadcast rmapsevents.alert.spawn, imageAlert

    _.extend $scope,
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
