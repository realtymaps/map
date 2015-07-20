module.exports =
  index: '/admin/'

  # states:
  login: 'login'
  logout: 'logout'
  mls: 'mls'
  normalize: 'normalize?id'
  jobs: 'jobs'
  jobsCurrent: '/current'
  jobsHistory: '/history?task'
  jobsQueue: '/queue'
  jobsTask: '/task'
  jobsSubtask: '/subtask'
  authenticating: 'authenticating'
  accessDenied: 'accessDenied'
  pageNotFound: '*path'

  # the urls for states are needed
  urls:
    login: '/admin/login'
    logout: '/admin/logout'
    mls: '/admin/mls'
    normalize: '/admin/normalize'
    jobs: '/admin/jobs'
    authenticating: '/admin/authenticating'
    accessDenied: '/admin/accessDenied'

