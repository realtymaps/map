app = require '../app.coffee'

app.run ($http, DSCacheFactory, rmapsMapCacheLogger) ->
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
      rmapsMapCacheLogger.debug "Expired: key: #{key}"

  #BEWARE THIS TURNS CACHING ON BY DEFAULT!!!!!!!!!!!!!!
  #http://stackoverflow.com/questions/14117653/how-to-cache-an-http-get-service-in-angularjs
  $http.defaults.cache = DSCacheFactory.get('defaultCache')
