app = require '../app.coffee'
frontendRoutes = require '../../../../common/config/routes.frontend.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

app.controller 'rmapsUserCtrl', ($scope, $rootScope, $location, $http, rmapsprincipal, rmapsevents) ->
  maxImagePixles = 200
  rmapsprincipal.getIdentity()
  .then (identity) ->

    {user, profiles} = identity
    user.full_name = if user.first_name and user.last_name then "#{user.first_name} #{user.last_name}" else ""
    user.name = user.full_name or user.username

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

      user: user
      profiles: profiles

      submit: ->
      ready: true
