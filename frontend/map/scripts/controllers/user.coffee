###global _:true###
app = require '../app.coffee'
frontendRoutes = require '../../../../common/config/routes.frontend.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

app.controller 'rmapsUserCtrl', (
$scope,
$rootScope,
$location,
$http,
$state,
rmapsEventConstants,
rmapsPrincipalService,
rmapsMainOptions,
$log,
rmapsUsStates
) ->

  {profile} = rmapsMainOptions.images.dimensions
  maxImagePixles = profile.width
  imageQuality = profile.quality

  spawnAlert = (msg) ->
    alert =
      type:'rm-info'
      msg: msg

    $rootScope.$broadcast rmapsEventConstants.alert.spawn, alert

  $scope.getStateName = (name) ->
    name.replace /user(.+)/, '$1'


  $scope.us_states = rmapsUsStates.all

  $http.get(backendRoutes.account_use_types.root)
  .then ({data}) ->
    $scope.accountUseTypes = data

  if $scope.user.company_id?
    $http.get("#{backendRoutes.company.root}/#{$scope.user.company_id}")
    .then ({data}) ->
      _.extend $scope.company, _.first data

  $http.get(backendRoutes.company.root)
  .then ({data}) ->
    $scope.companies = _.indexBy data, 'id'


  $scope.maxImagePixles = maxImagePixles
  $scope.imageQuality = imageQuality

  $scope.user.submit = () ->
    $http.put backendRoutes.userSession.root, @

  $scope.company = _.merge $scope.company || {},
    submit: () ->
      $http.post backendRoutes.userSession.companyRoot, @

  $scope.imageForm =
    cropBlob: ''
    clearErrors: () ->
      $scope.$evalAsync ->
        $scope.imageForm.errors = {}

    toRender: () ->
      if @cropBlob?.length
        return @cropBlob
      if $scope.user.account_image_id?
        return @blob || backendRoutes.userSession.image
      '/assets/avatar.svg'

    save: () ->
      return spawnAlert 'No Image to Save.' unless @blob?

      if _.keys(@errors).length
        _.each @errors, (e) ->
          spawnAlert e
        return

      $http.put backendRoutes.userSession.image, blob: @cropBlob
      .success =>
        delete @cropBlob
        delete @blob

  $scope.companyImageForm =
    cropBlob: ''

    clearErrors: () ->
      $scope.$evalAsync ->
        $scope.companyImageForm.errors = {}

    toRender: () ->
      if @cropBlob?.length
        return @cropBlob
      if $scope.company.account_image_id?
        return @blob || backendRoutes.userSession.companyImage.replace(':account_image_id', $scope.company.account_image_id)
      frontendRoutes.avatar

    save: () ->
      return spawnAlert 'No Image to Save.' unless @blob?

      if _.keys(@errors).length
        _.each @errors, (e) ->
          spawnAlert e
        return

      $http.put backendRoutes.userSession.companyImage.replace(':account_image_id',''), _.extend(blob: @cropBlob, $scope.company)
      .success =>
        delete @cropBlob
        delete @blob

  $scope.pass =
    username: '' + $scope.user.username

    change: () ->
      if @password != @confirmPassword
        @errorMsg = 'passwords do not match!'
      else
        delete @errorMsg

    submit: () ->
      if @password != @confirmPassword
        return
      $http.put backendRoutes.userSession.updatePassword, password: @password

  $scope.ready = true
