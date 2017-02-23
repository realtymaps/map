L = require('leaflet');
require('./l.draw.js');


module.exports = L.Draw.Feature = L.Draw.Feature.extend({
  _fireEditedEvent: function (layer) {
		this._map.fire('draw:edited', { layer: layer, layerType: this.type });
	}
})
