module.exports =
  index: '/admin/'

  # states:
  login: 'login'
  logout: 'logout'

  dataSource: 'dataSource'
  mls: '/mls'
  normalize: '/normalize?id=&list='
  county: '/county?id=&list='

  jobs: 'jobs'
  jobsCurrent: '/current'
  jobsHistory: '/history?task=&current=&timerange='
  jobsHealth: '/health'
  jobsQueue: '/queue'
  jobsTask: '/task'
  jobsSubtask: '/subtask'

  utils: 'utils'
  utilsFipsCodes: '/fips'
  utilsMail: '/mail'

  users: 'users'
  usersCustomers: '/customers'

  authenticating: 'authenticating'
  accessDenied: 'accessDenied'
  pageNotFound: '*path'
