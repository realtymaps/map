require('./l.handler.js')
Object.assign = Object.assign || require('object-assign')

module.exports = L.EditToolbar.Delete = L.EditToolbar.Delete.extend({
  revertLayers: function () {
    if(!this._deletedLayers)
      return;
    // Iterate of the deleted layers and add them back into the featureGroup
    this._deletedLayers.eachLayer(function (layer) {
      this._deletableLayers.addLayer(layer);
      layer.fire('revert-deleted', { layer: layer });
    }, this);
  }
})
