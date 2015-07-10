module.exports =
  index: '/admin/'

  # states:
  login: 'login'
  logout: 'logout'
  mls: 'mls'
  normalize: 'normalize?id'
  authenticating: 'authenticating'
  accessDenied: 'accessDenied'
  pageNotFound: '*path'

  # the urls for states are needed
  urls:
    login: '/admin/login'
    logout: '/admin/logout'
    mls: '/admin/mls'
    normalize: '/admin/normalize'
    authenticating: '/admin/authenticating'
    accessDenied: '/admin/accessDenied'
  
