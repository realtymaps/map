module.exports = {
	_initModeHandler: function (handler) {
		if(!this._modes)
			this._modes = {}

		var type = handler.type;

		this._modes[type] = {};

		this._modes[type].handler = handler;

		this._modes[type].handler
			.on('enabled', this._handlerActivated, this)
			.on('disabled', this._handlerDeactivated, this);
	},
	addToolbar: function (map) {
		var modeHandlers = this.getModeHandlers(map), key;

		this._map = map;

		for (key in modeHandlers) {
			if (modeHandlers[key].enabled) {
				this._initModeHandler(modeHandlers[key].handler);
			}
		}

		return {};
	},
	removeToolbar: function () {
		// Dispose each handler
		for (var handlerId in this._modes) {
			if (this._modes.hasOwnProperty(handlerId)) {
				// Make sure is disabled
				this._modes[handlerId].handler.disable()

				// Unbind handler
				this._modes[handlerId].handler
					.off('enabled', this._handlerActivated, this)
					.off('disabled', this._handlerDeactivated, this)

				this._modes[handlerId].handler.clearAllEventListeners()
			}
		}
		this._modes = {};
	}
}
