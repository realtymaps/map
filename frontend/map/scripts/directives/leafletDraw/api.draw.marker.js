module.exports = L.Draw.Marker = L.Draw.Marker.extend({

  enable: function () {
		if (this._enabled) return

		L.Handler.prototype.enable.apply(this, arguments)

		this.fire('enabled', { handler: this.type })

		this._map.fire('draw:drawstart', { layerType: this.type })
	},

  addHooks: function (e, options) {

    if(!options)
      options = {}

		L.Draw.Feature.prototype.addHooks.call(this)

		if (this._map) {
			this._tooltip.updateContent({ text: L.drawLocal.draw.handlers.marker.tooltip.start })

			// Same mouseMarker as in Draw.Polyline
			if (!this._mouseMarker) {
				this._mouseMarker = L.marker(this._map.getCenter(), {
					icon: options.icon || L.divIcon({
						className: 'leaflet-mouse-marker',
						iconAnchor: [20, 20],
						iconSize: [40, 40]
					}),
					opacity: options.opacity || 0,
					zIndexOffset: options.zIndexOffset || this.options.zIndexOffset
				})
			}

      this._onClickExt = function(e){
        this._onClick(e, options)
      }

      this._onMouseMoveExt = function(e){
        this._onMouseMove(e, options)
      }

      this._onTouchExt = function(e){
        this._onTouch(e, options)
      }

			this._mouseMarker
      .on('click', this._onClickExt, this)
			.addTo(this._map)

			this._map.on('mousemove', this._onMouseMoveExt, this)

			this._map.on('click', this._onMouseMoveExt, this)
		}
	},

  removeHooks: function () {
		L.Draw.Feature.prototype.removeHooks.call(this);

		if (this._map) {
			if (this._marker) {
				this._marker.off('click', this._onClick, this);
				this._map
					.off('click', this._onClickExt, this)
					.off('click', this._onTouchExt, this)
					.removeLayer(this._marker);
				delete this._marker;
			}

			this._mouseMarker.off('click', this._onClickExt, this);
			this._map.removeLayer(this._mouseMarker);
			delete this._mouseMarker;

			this._map.off('mousemove', this._onMouseMoveExt, this);
		}
	},

  _onMouseMove: function (e, options) {
		var latlng = e.latlng
    var _this = this

    if (this._tooltip)
		  this._tooltip.updatePosition(latlng)

		this._mouseMarker.setLatLng(latlng)

		if (!this._marker) {
			this._marker = new L.Marker(latlng, {
				icon: options.icon || this.options.icon,
				zIndexOffset: options.zIndexOffset || this.options.zIndexOffset
			})
			// Bind to both marker and map to make sure we get the click event.
			this._marker.on('click', function(e){
        _this._onClick(e, options)
      })

			this._map
			.on('click', function(e){
        _this._onClick(e, options)
      })
			.addLayer(this._marker)
		}
		else {
			latlng = this._mouseMarker.getLatLng()
			this._marker.setLatLng(latlng)
		}
	},

	_onClick: function (e, options) {
		this._fireCreatedEvent(e, options)

		this.disable()
		if (options.repeatMode || this.options.repeatMode) {
			this.enable()
		}
	},

	_onTouch: function (e, options) {
		// called on click & tap, only really does any thing on tap
		this._onMouseMove(e, options) // creates & places marker
		this._onClick(e, options) // permenantly places marker & ends interaction
	},

	_fireCreatedEvent: function (e, options) {
    if(!options)
      options = {}

		var marker = new L.Marker.Touch(this._marker.getLatLng(), {
      icon: options.icon || this.options.icon
    })
		L.Draw.Feature.prototype._fireCreatedEvent.call(this, marker)
	}
})
