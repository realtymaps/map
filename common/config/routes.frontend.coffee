module.exports =
  index:          '/'
  login:          'login'
  logout:         'logout'
  map:            'map'
  authenticating: 'authenticating'
  accessDenied:   'accessDenied'
  snail:          'snail'
  profiles:       'profiles'
  user:           'user'
  history:        'history'
  properties:     'properties'
  projects:       'projects'
  project:        'project?id'
  neighbourhoods: 'neighbourhoods'
  notes:          'notes'
  favorites:      'favorites'
  addProjects:    'addProjects'
  sendEmailModal: 'sendEmailModal'
  createNewEmail: 'newEmail'

  mail:           'mail'
  mailWizard:     'mailWizard'
  editTemplate:   '/editTemplate'

  avatar:         '/assets/avatar.svg'
  mocks:
    email:        '/json/emails.json'
    history:      '/json/history.json'
  # Note '*path' below is a special catchall syntax for ui-router
  pageNotFound:   '*path'
