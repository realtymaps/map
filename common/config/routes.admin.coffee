module.exports =
  index: '/admin/'

  # states:
  login: 'login'
  logout: 'logout'

  dataSource: 'dataSource'
  mls: '/mls'
  normalize: '/normalize?id'
  county: '/county?id=&list='

  jobs: 'jobs'
  jobsCurrent: '/current'
  jobsHistory: '/history?task'
  jobsHealth: '/health'
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
    jobs: '/admin/jobs'
    dataSource: '/admin/dataSource'
    authenticating: '/admin/authenticating'
    accessDenied: '/admin/accessDenied'


