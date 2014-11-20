factory = require './handle.base.geohash.coffee'
module.exports = () ->
  all = new factory '../../services/service.properties.parcels'
  polys = new factory '../../services/service.properties.parcels', 'getAllPolys'
  getAll: all.getAll
  getAllPolys: polys.getAllPolys