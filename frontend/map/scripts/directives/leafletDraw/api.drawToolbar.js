require('./l.handler.js')
require('./l.draw.feature.js')
require('./l.draw.marker.js')
require('./l.draw.text.js')

var OurToolBar = require('./api.Toolbar.js')
Object.assign = Object.assign || require('object-assign')
/*
  Mods: L.DrawToolbar
  Goal:
    To be more of an API interface to interact with the DrawObject instead of
    actually adding a toolbar to the map.
*/

module.exports = L.DrawToolbar.extend(Object.assign({}, OurToolBar, {

	initialize: function (options) {

		L.setOptions(this, options)

		// Ensure that the options are merged correctly since L.extend is only shallow
		for (var type in this.options) {
			if (this.options.hasOwnProperty(type)) {
				if (options[type]) {
					options[type] = L.extend({}, this.options[type], options[type])
				}
			}
		}

	},

	getModeHandlers: function (map) {
		return {
			polyline: {
				enabled: this.options.polyline,
				handler: new L.Draw.Polyline(map, this.options.polyline),
				title: _.get(this.options.polyline,"buttons.title") ||
          L.drawLocal.draw.toolbar.buttons.polyline
			},
			polygon: {
				enabled: this.options.polygon,
				handler: new L.Draw.Polygon(map, this.options.polygon),
				title: _.get(this.options.rectangle,"buttons.title") ||
          L.drawLocal.draw.toolbar.buttons.polygon
			},
			rectangle: {
				enabled: this.options.rectangle,
				handler: new L.Draw.Rectangle(map, this.options.rectangle),
				title: _.get(this.options.rectangle,"buttons.title") ||
          L.drawLocal.draw.toolbar.buttons.rectangle
			},
			circle: {
				enabled: this.options.circle,
				handler: new L.Draw.Circle(map, this.options.circle),
				title: _.get(this.options.circle, "buttons.title") ||
          L.drawLocal.draw.toolbar.buttons.circle
			},
			marker: {
				enabled: this.options.marker,
				handler: new L.Draw.Marker(map, this.options.marker),
				title: _.get(this.options.marker, "buttons.title") ||
          L.drawLocal.draw.toolbar.buttons.marker
			},
			text: {
				enabled: this.options.textlabel,
				handler: new L.Draw.TextLabel(map, this.options.textlabel),
				title: L.drawLocal.draw.toolbar.buttons.textlabel
			}
		}
	},

	// Get the actions part of the toolbar
	getActions: function (handler) {
		return [
			{
				enabled: handler.completeShape,
				title: _.get(this.options.toolbar, "finish.title")
          || L.drawLocal.draw.toolbar.finish.title,
				text:  _.get(this.options.toolbar, "finish.text")
          || L.drawLocal.draw.toolbar.finish.text,
				callback: handler.completeShape,
				context: handler
			},
			{
				enabled: handler.deleteLastVertex,
				title: _.get(this.options.toolbar, "undo.title")
          || L.drawLocal.draw.toolbar.undo.title,
				text: _.get(this.options.toolbar, "undo.text")
          || L.drawLocal.draw.toolbar.undo.text,
				callback: handler.deleteLastVertex,
				context: handler
			},
			{
				title: _.get(this.options.toolbar, "actions.title")
          || L.drawLocal.draw.toolbar.actions.title,
				text: _.get(this.options.toolbar, "actions.text")
          || L.drawLocal.draw.toolbar.actions.text,
				callback: this.disable,
				context: this
			}
		]
	}
}))
