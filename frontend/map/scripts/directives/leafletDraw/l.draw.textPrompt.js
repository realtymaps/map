L = require('leaflet');
require('leaflet-draw/dist/leaflet.draw.js');

module.exports = L.Draw.TextPrompt = function(a) {
  var b = prompt("Please enter your text", a.value);
  null != b && "" != b.trim() && (a.value = b,
    a.contentEditable = !1,
    a.hidden = !0,
    a.nextSibling.hidden = !1,
    a.nextSibling.textContent = a.value)
}
