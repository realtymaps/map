L = require('leaflet')
require('./l.draw.textPrompt.js')
require('leaflet-draw/dist/leaflet.draw.js');

module.exports = L.Draw.TextLabel = L.Draw.Feature.extend({
  statics: {
    TYPE: "textlabel"
  },
  options: {
    repeatMode: !1,
    zIndexOffset: 2e3,
    color: "#000000",
    fontSize: "14px"
  },
  initialize: function(map, options) {
    this.type = L.Draw.TextLabel.TYPE,
      L.Draw.Feature.prototype.initialize.call(this, map, options),
      this._map = map
  },
  addHooks: function() {
    L.Draw.Feature.prototype.addHooks.call(this)

    if(this._map){
      this._tooltip.updateContent({text: "Text Label"})
      this._mouseMarker = this._mouseMarker || L.marker(this._map.getCenter(), {
        icon: L.divIcon({
          className: "leaflet-textlabel",
          iconAnchor: [20, 20],
          iconSize: [40, 40]
        }),
        opacity: 0,
        zIndexOffset: this.options.zIndexOffset
      })

      this._mouseMarker.on("click", this._onClick, this).addTo(this._map)
      this._map.on("mousemove", this._onMouseMove, this)
      this._map.on("click", this._onTouch, this)
    }
  },
  removeHooks: function() {
    L.Draw.Feature.prototype.removeHooks.call(this),
      this._map && (this._textlabel && (this._textlabel.off("click", this._onClick, this),
          this._map.off("click", this._onClick, this).off("click", this._onTouch, this).removeLayer(this._textlabel),
          delete this._textlabel),
        this._mouseMarker.off("click", this._onClick, this),
        this._map.removeLayer(this._mouseMarker),
        delete this._mouseMarker,
        this._map.off("mousemove", this._onMouseMove, this))
  },
  _onMouseMove: function(e) {
    var latLng = e.latlng;

    this.options.icon = this._createDivIcon()
    this._tooltip.updatePosition(latLng)
    this._mouseMarker.setLatLng(latLng)
    if (this._textlabel) {
      latLng = this._mouseMarker.getLatLng()
      this._textlabel.setLatLng(latLng)
    }
    else {
      this._textlabel = new L.Marker(latLng, {
        icon: this.options.icon,
        zIndexOffset: this.options.zIndexOffset
      })
      this._textlabel.on("click", this._onClick, this)
      this._map.on("click", this._onClick, this).addLayer(this._textlabel)
    }

  },
  _onClick: function() {
    this._fireCreatedEvent()
    this.disable()
    this.options.repeatMode && this.enable()
  },
  _onTouch: function(e) {
    this._onMouseMove(e),
      this._onClick()
  },
  _onFocus: function(e) {

    var marker = e.target,
      firstChild = marker._icon.firstChild,
      _this = this;

    if ("false" != firstChild.contentEditable) {
      if(!marker.options.fontSize || !marker.options.color){
        marker._icon.style.fontSize = marker.options.fontSize = this.options.fontSize
        marker._icon.style.color = marker.options.color = this.options.color
      }

      firstChild.nextSibling.hidden = !0
      firstChild.hidden = !1
      firstChild.contentEditable = !0
      firstChild.focus()
      var _this = this;

      firstChild.onblur = function(e) {
        var target = e.target;
        if (target.value){
          target.contentEditable = false
          target.hidden = true
          target.nextSibling.hidden = false
          target.nextSibling.textContent = target.value
          _this._map.fire("draw:textareaBlur", {})
          // update the real html we care about
          delete marker.ignoreSave
          marker.options.icon.options.html = target.outerHTML + target.nextSibling.outerHTML
          L.Draw.Feature.prototype._fireCreatedEvent.call(_this, marker)
        }
      }

      firstChild.onkeyup = function(e) {
        if ("Enter" == e.keyIdentifier){
          firstChild.blur()
        }
      }

    }
  },

  _fireCreatedEvent: function() {
    var marker = new L.Marker.Touch(this._textlabel.getLatLng(), {
      writable: !0,
      icon: this.options.icon
    })

    marker.on("add", this._onFocus, this)
    marker.ignoreSave = true
    L.Draw.Feature.prototype._fireCreatedEvent.call(this, marker)
  },

  _createInput: function(a, b) {
    var input = L.DomUtil.create("input", b, this._container);

    input.type = "text"
    input.value = ""
    input.placeholder = a

    L.DomEvent.disableClickPropagation(input).on(input, "blur", function() {
      console.log("input blur")
    }, this).on(input, "focus", function() {
      console.log("input focus")
    }, this)

    return input
  },

  _createDivIcon: function() {
    var agent = navigator.userAgent.toLowerCase(),
      isAndroid = agent.indexOf("android") > -1,
      textAreaTemplate = '<textarea class="textlabel-textarea"></textarea><div class="textlabel-text" hidden></div>';

    if (isAndroid)
      textAreaTemplate = '<textarea autofocus class="textlabel-textarea" onclick="L.Draw.TextPrompt(this);"></textarea><div contenteditable="true" class="textlabel-text" hidden></div>'

    return new L.divIcon({
      className: "textlabel",
      html: textAreaTemplate,
      iconSize: [40, 40]
    });
  }

})
