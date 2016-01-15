Explosion = require('./explosion.js')

var boomboomFact = function(render){

	var BoomBoom = {
		_ctx: null,
		_data: null,
		_last: {
			ts: 0,
			value: 0
		},
		_decay: 300,

		handleEvent: function(e) {
			switch (e.type) {
				case "load":
					this._init()
				break

				case "ended":
	 			break

				case "submit":
					e.preventDefault()
				break

				case "change":

				break

				case "click":
					render.scene.push(new Explosion(render.gl, 1))
				break
			}
		},

		_init: function() {
			this._build()
			// this._next()

			this._tick = this._tick.bind(this)
			this._timerId = setInterval(this._tick, 15)
		},

		_build: function(element) {
			if(!element)
				document.querySelector("body").addEventListener("click", this)
			else
				element.addEventListener("click", this)
		},

		_kill: function(){
			clearInterval(this._timerId)
		},

		_tick: function() {
			/* current values */
			var now = Date.now()
			var value = Math.random() * 20

			/* diffs */
			var delta = value-this._last.value
			var timeDiff = now - this._last.ts

			/* always maintain last */
			this._last.value = value

			if (timeDiff < this._decay) { /* decay */
				this._last.value = value
				return
			}


			if (delta > 15) {
				this._last.ts = now
				var force = delta / 50
				render.scene.push(new Explosion(render.gl, force))

				/* one more! */
				if (force > 1.1) { render.scene.push(new Explosion(render.gl, 1)) }
			}
		}
	}
	return BoomBoom
}
module.exports = boomboomFact
