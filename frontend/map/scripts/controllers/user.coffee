###global _:true###
app = require '../app.coffee'
frontendRoutes = require '../../../../common/config/routes.frontend.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

app.controller 'rmapsUserCtrl', ($scope, $rootScope, $location, $http, rmapsevents,
rmapsPrincipalService, rmapsMainOptions, $log, rmapsUsStatesService) ->

  {profile} = rmapsMainOptions.images.dimensions
  maxImagePixles = profile.width
  imageQuality = profile.quality
  rmapsPrincipalService.getIdentity().then ->
    user = $rootScope.user
    rmapsUsStatesService.getAll().then (states) ->
      $scope.us_states = states

    $http.get(backendRoutes.account_use_types.root).then (data) ->
      $scope.accountUseTypes = data.data

    if user.company_id?
      $http.get("#{backendRoutes.company.root}/#{user.company_id}").then (data) ->
        _.extend $scope.company, _.first data.data

    $http.get(backendRoutes.company.root).then (data) ->
      _.merge $scope,
        companies: _.indexBy data.data, 'id'

    spawnAlert = (msg) ->
      alert =
        type:'rm-info'
        msg: msg

      $rootScope.$broadcast rmapsevents.alert.spawn, alert

    _.merge $scope,
      # companies:
      #   changed: ->
      #     _.merge $scope.company, $scope.companies[$scope.user.company_id]
      user: _.extend _.clone($rootScope.user, true),
        submit: ->
          $http.put backendRoutes.userSession.root, @
      company:
        submit: ->
          $http.post backendRoutes.userSession.companyRoot, @
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
            return @blob || backendRoutes.userSession.image
          '/assets/avatar.svg'
        save: ->
          return spawnAlert 'No Image to Save.' unless @blob?

          if _.keys(@errors).length
            _.each @errors, (e) ->
              spawnAlert e
            return

          $http.put backendRoutes.userSession.image, blob: @cropBlob
          .success =>
            delete @cropBlob
            delete @blob

      companyImageForm:
        cropBlob: ''
        clearErrors: ->
          $scope.$evalAsync ->
            $scope.companyImageForm.errors = {}
        toRender: ->
          if @cropBlob.length
            return @cropBlob
          if $scope.company.account_image_id?
            return @blob || backendRoutes.userSession.companyImage.replace(':account_image_id', $scope.company.account_image_id)
          frontendRoutes.avatar
        save: ->
          return spawnAlert 'No Image to Save.' unless @blob?

          if _.keys(@errors).length
            _.each @errors, (e) ->
              spawnAlert e
            return

          $http.put backendRoutes.userSession.companyImage.replace(':account_image_id',''), _.extend(blob: @cropBlob, $scope.company)
          .success =>
            delete @cropBlob
            delete @blob
      pass:
        username: '' + user.username
        change: ->
          if @password != @confirmPassword
            @errorMsg = 'passwords do not match!'
          else
            delete @errorMsg
        submit: ->
          if @password != @confirmPassword
            return
          $http.put backendRoutes.userSession.updatePassword, password: @password
      ready: true
