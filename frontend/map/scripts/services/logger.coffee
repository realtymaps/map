app = require '../app.coffee'
app.service 'Logger'.ourNs(), [ 'uiGmapLogger', ($log) -> $log.spawn() ]