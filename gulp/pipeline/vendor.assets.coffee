module.exports = [
  'leaflet/dist/images/*'
  'leaflet-search/images/*'
].map (f) ->
  './node_modules/' + f
