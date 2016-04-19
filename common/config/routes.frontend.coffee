module.exports =
  index:          '/'
  login:          'login'
  logout:         'logout'
  map:            'map?project_id&property_id'
  authenticating: 'authenticating'
  accessDenied:   'accessDenied'
  snail:          'snail'
  profiles:       'profiles'
  history:        'history'
  properties:     'properties'
  property:       'property/:id'
  projects:       'projects'
  project:        'project/:id'

  # Child state URLs must start with / to avoid doubles
  projectClients: '/clients'
  projectFavorites: '/favorites'
  projectNotes:   '/notes'
  projectPins:    '/pins'
  projectNeighbourhoods: '/neighbourhoods'

  user:           'user'
  userMLS:        '/userMLS'
  userPaymentMethod: '/userPaymentMethod'
  userNotifications: '/userNotifications'
  userTeamMembers: '/userTeamMembers'
  userPaymentHistory: '/userPaymentHistory'
  
  neighbourhoods: 'neighbourhoods'
  notes:          'notes'
  favorites:      'favorites'
  addProjects:    'addProjects'
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

