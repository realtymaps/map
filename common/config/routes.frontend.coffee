module.exports =
  index:          '/'
  login:          'login'
  logout:         'logout'
  map:            'map?project_id'
  authenticating: 'authenticating'
  accessDenied:   'accessDenied'
  snail:          'snail'
  profiles:       'profiles'
  user:           'user'
  history:        'history'
  mail:           'mail'
  properties:     'properties'
  projects:       'projects'
  project:        'project?id'
  neighbourhoods: 'neighbourhoods'
  notes:          'notes'
  favorites:      'favorites'
  addProjects:    'addProjects'
  sendEmailModal: 'sendEmailModal'
  createNewEmail: 'newEmail'

  avatar:         '/assets/avatar.svg'
  mocks:
    email:        '/json/emails.json'
    history:      '/json/history.json'
  # Note '*path' below is a special catchall syntax for ui-router
  pageNotFound:   '*path'
