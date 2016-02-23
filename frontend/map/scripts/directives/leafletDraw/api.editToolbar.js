/*L.Map.mergeOptions({
	editControl: true
})*/

module.exports = L.EditToolbar.extend({

	initialize: function (options) {
		// Need to set this manually since null is an acceptable value here
		if (options.edit) {
			if (typeof options.edit.selectedPathOptions === 'undefined') {
				options.edit.selectedPathOptions = this.options.edit.selectedPathOptions
			}
			options.edit.selectedPathOptions = L.extend({}, this.options.edit.selectedPathOptions, options.edit.selectedPathOptions)
		}

		if (options.remove) {
			options.remove = L.extend({}, this.options.remove, options.remove)
		}

		this._toolbarClass = 'leaflet-draw-edit'
		// L.Class.prototype.initialize.call(this, options)

		this._selectedFeatureCount = 0
	},

	getModeHandlers: function (map) {
		var featureGroup = this.options.featureGroup
		return {
			edit: {
				enabled: this.options.edit,
				handler: new L.EditToolbar.Edit(map, {
					featureGroup: featureGroup,
					selectedPathOptions: this.options.edit.selectedPathOptions
				}),
				title: _.get(this.options.edit, "buttons.title") ||
          L.drawLocal.edit.toolbar.buttons.edit
			},
			remove: {
				enabled: this.options.remove,
				handler: new L.EditToolbar.Delete(map, {
					featureGroup: featureGroup
				}),
				title: _.get(this.options.remove, "buttons.title") ||
          L.drawLocal.edit.toolbar.buttons.remove
			}
		}
	},

  getActions: function () {
		return {
			edit: {
				title: L.drawLocal.edit.toolbar.actions.save.title,
				text: L.drawLocal.edit.toolbar.actions.save.text,
				callback: this._save,
				context: this
			},
			remove: {
				title: L.drawLocal.edit.toolbar.actions.cancel.title,
				text: L.drawLocal.edit.toolbar.actions.cancel.text,
				callback: this.disable,
				context: this
			}
		};
	},

  addToolbar: function (map) {
		// var container = L.Toolbar.prototype.addToolbar.call(this, map);

		this._checkDisabled();

		this.options.featureGroup.on('layeradd layerremove', this._checkDisabled, this);

		// return container;
	},

	removeToolbar: function () {
		this.options.featureGroup.off('layeradd layerremove', this._checkDisabled, this);

		// L.Toolbar.prototype.removeToolbar.call(this);
	},

	disable: function () {
		if (!this.enabled()) { return; }

		this._activeMode.handler.revertLayers();

		// L.Toolbar.prototype.disable.call(this);
	},

	_save: function () {
		this._activeMode.handler.save();
		this._activeMode.handler.disable();
	},

	_checkDisabled: function () {
		var featureGroup = this.options.featureGroup,
			hasLayers = featureGroup.getLayers().length !== 0,
			button;

		if (this.options.edit) {
			button = this._modes[L.EditToolbar.Edit.TYPE].button;

			if (hasLayers) {
				L.DomUtil.removeClass(button, 'leaflet-disabled');
			} else {
				L.DomUtil.addClass(button, 'leaflet-disabled');
			}

			button.setAttribute(
				'title',
				hasLayers ?
				L.drawLocal.edit.toolbar.buttons.edit
				: L.drawLocal.edit.toolbar.buttons.editDisabled
			);
		}

		if (this.options.remove) {
			button = this._modes[L.EditToolbar.Delete.TYPE].button;

			if (hasLayers) {
				L.DomUtil.removeClass(button, 'leaflet-disabled');
			} else {
				L.DomUtil.addClass(button, 'leaflet-disabled');
			}

			button.setAttribute(
				'title',
				hasLayers ?
				L.drawLocal.edit.toolbar.buttons.remove
				: L.drawLocal.edit.toolbar.buttons.removeDisabled
			);
		}
	}
})