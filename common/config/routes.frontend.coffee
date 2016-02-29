module.exports =
  index:          '/'
  login:          'login'
  logout:         'logout'
  map:            'map?project_id&property_id'
  authenticating: 'authenticating'
  accessDenied:   'accessDenied'
  snail:          'snail'
  profiles:       'profiles'
  user:           'user'
  history:        'history'
  properties:     'properties'
  property:       'property/:id'
  projects:       'projects'
  project:        'project/:id'
  projectClients: 'project/:id/clients'
  projectFavorites: 'project/:id/favorites'
  projectNotes:   'project/:id/notes'
  projectPins:    'project/:id/pins'
  projectNeighbourhoods: 'project/:id/neighbourhoods'
  neighbourhoods: 'neighbourhoods'
  notes:          'notes'
  favorites:      'favorites'
  addProjects:    'addProjects'
  sendEmailModal: 'sendEmailModal'
  createNewEmail: 'newEmail'
  onboarding:     'onboarding'
  onboardingPlan: '/plan'

  mail:           'mail'
  mailWizard:     'mailWizard?id'
  recipientInfo:  '/recipientInfo'
  campaignInfo:   '/campaignInfo'
  selectTemplate: '/selectTemplate'
  editTemplate:   '/editTemplate'
  review:   '/review'

  avatar:         '/assets/avatar.svg'
  mocks:
    email:        '/json/emails.json'
    history:      '/json/history.json'
  # Note '*path' below is a special catchall syntax for ui-router
  pageNotFound:   '*path'
