###global _:true###
app = require '../app.coffee'

module.exports = app.constant 'rmapsRouteProfileResolve', ($location, $log, $state, $stateParams, rmapsProfilesService, currentIdentity) ->
  # Does the state or location define a project id?
  if $state.current.projectParam? and $stateParams[$state.current.projectParam]?
    $log.debug "Loading project based on $state.current.projectParam #{$state.current.projectParam}"
    project_id = Number($stateParams[$state.current.projectParam])

  else if $location.search().project_id?
    $log.debug "Loading project based on ?project_id"
    project_id = Number($location.search().project_id)

  if currentIdentity
    # Determine if the state defined project exists
    if project_id?
      profile = (_.find(currentIdentity.profiles, project_id: project_id))

    # Does the defined project exist?
    if profile?
      $log.debug "Set current profile to", profile
      return rmapsProfilesService.setCurrentProfile profile
    else
      # Default to the session profile or the first profile for the identity
      $log.debug "Loading profile based on identity.currentProfileId #{currentIdentity.currentProfileId}"
      return rmapsProfilesService.setCurrentProfileByIdentity currentIdentity
