module.exports = L.Handler = L.Handler.extend({
	enable: function (e, options) {
		if (this._enabled) { return; }

		this._enabled = true;
		this.addHooks(e, options);
	}
});
