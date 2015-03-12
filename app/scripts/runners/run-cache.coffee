app = require '../app.coffee'

app.run [ '$http', 'DSCacheFactory', 'Logger'.ourNs(), ($http, DSCacheFactory, $log) ->
  #init caches here begining w default
  DSCacheFactory 'defaultCache',
    capacity: 500
    maxAge: 74000 #14 min
    deleteOnExpire: 'aggressive'
    recycleFreq: 60000 #minute
    cacheFlushInterval: 3600000 #hour
    storageMode: 'sessionStorage' #options (memory , localStorage, sessionStorage)
    verifyIntegrity: true
    onExpire: (key, value) ->
      $log "Cache Expired: key: #{key}, value: #{value}"


  $http.defaults.cache = DSCacheFactory.get('defaultCache')

]