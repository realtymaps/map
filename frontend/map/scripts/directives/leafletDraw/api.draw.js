var DrawToolbar = require('./api.drawToolbar.js')
var EditToolbar = require('./api.editToolbar.js')

module.exports = L.Class.extend({

	options: {
		position: 'topleft',
		draw: {},
		edit: false
	},

	initialize: function (options) {
		if (L.version < '0.7') {
			throw new Error('Leaflet.draw 0.2.3+ requires Leaflet 0.7.0+. Download latest from https://github.com/Leaflet/Leaflet/')
		}

		L.Class.prototype.initialize.call(this, options)

		var toolbar

		this._toolbars = {}

		// Initialize toolbars
		if (DrawToolbar && this.options.draw) {
			toolbar = new DrawToolbar(this.options.draw)

			this._toolbars[DrawToolbar.TYPE] = toolbar

			// Listen for when toolbar is enabled
			this._toolbars[DrawToolbar.TYPE].on('enable', this._toolbarEnabled, this)
		}

		if (EditToolbar && this.options.edit) {
			toolbar = new EditToolbar(this.options.edit)

			this._toolbars[EditToolbar.TYPE] = toolbar

			// Listen for when toolbar is enabled
			this._toolbars[EditToolbar.TYPE].on('enable', this._toolbarEnabled, this)
		}
		L.toolbar = this //set global var for editing the toolbar
	},

	onAdd: function (map) {
		var toolbarContainer

		for (var toolbarId in this._toolbars) {
			if (this._toolbars.hasOwnProperty(toolbarId)) {
				toolbarContainer = this._toolbars[toolbarId].addToolbar(map)
			}
		}

		return container
	},

	onRemove: function () {
		for (var toolbarId in this._toolbars) {
			if (this._toolbars.hasOwnProperty(toolbarId)) {
				this._toolbars[toolbarId].removeToolbar()
			}
		}
	},

	setDrawingOptions: function (options) {
		for (var toolbarId in this._toolbars) {
			if (this._toolbars[toolbarId] instanceof DrawToolbar) {
				this._toolbars[toolbarId].setOptions(options)
			}
		}
	},

	_toolbarEnabled: function (e) {
		var enabledToolbar = e.target

		for (var toolbarId in this._toolbars) {
			if (this._toolbars[toolbarId] !== enabledToolbar) {
				this._toolbars[toolbarId].disable()
			}
		}
	}
})
