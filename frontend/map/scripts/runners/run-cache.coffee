app = require '../app.coffee'

app.run ($http, DSCacheFactory, $log) ->
  #init caches here begining w default
  DSCacheFactory 'defaultCache',
    #capacity: 100000
    maxAge: 74000 #14 min
    deleteOnExpire: 'aggressive'
    recycleFreq: 30000 #30 seconds
    cacheFlushInterval: 3600000 #hour
    storageMode: 'memory' #options (memory , localStorage, sessionStorage)
    verifyIntegrity: true
    onExpire: (key, value) ->
      $log.debug "Cache Expired: key: #{key}"

  $http.defaults.cache = DSCacheFactory.get('defaultCache')
