###global _:true###
app = require '../app.coffee'

app.constant 'rmapsRouteProfileResolve', (
$location
$log
$state
$stateParams
rmapsProfilesService
currentIdentity
) ->
  "ngInject"
  $log = $log.spawn 'rmapsRouteProfileResolve'
  # Does the state or location define a project id?
  if $state.toState?.projectParam? and $state.toParams?[$state.toState.projectParam]?
    $log.debug "Loading project based on $state.current.projectParam #{$state.toState.projectParam}"
    project_id = Number($state.toParams[$state.toState.projectParam])

  else if $location.search().project_id?
    $log.debug "Loading project based on ?project_id"
    project_id = Number($location.search().project_id)

  if currentIdentity
    # Determine if the state defined project exists
    if project_id?
      profile = (_.find(currentIdentity.profiles, project_id: project_id))

    # Does the defined project exist?
    if profile?
      $log.debug "Set current profile to", profile.id
      return rmapsProfilesService.setCurrentProfile profile
    else
      # Default to the session profile or the first profile for the identity
      $log.debug "Loading profile based on identity.currentProfileId #{currentIdentity.currentProfileId}"
      return rmapsProfilesService.setCurrentProfileByIdentity currentIdentity

app.factory 'rmapsRouteProfileResolveFactory', (
$location
$log
$state
$stateParams
rmapsProfilesService
rmapsRouteProfileResolve
rmapsPrincipalService
) ->
  () ->
    rmapsPrincipalService
    .getIdentity().then (identity) ->
      rmapsRouteProfileResolve($location
      $log
      $state
      $stateParams
      rmapsProfilesService
      identity)
