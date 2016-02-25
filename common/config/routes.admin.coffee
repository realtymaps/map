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
  jobsHistory: '/history?task=&current=&timerange='
  jobsHealth: '/health'
  jobsQueue: '/queue'
  jobsTask: '/task'
  jobsSubtask: '/subtask'

  authenticating: 'authenticating'
  accessDenied: 'accessDenied'
  pageNotFound: '*path'
