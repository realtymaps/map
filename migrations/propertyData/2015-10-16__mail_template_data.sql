INSERT INTO mail_templates (type, style, body) 
VALUES (
  'letter',
  '
    {
    "*, *:before, *:after": {
      "-webkit-box-sizing": "border-box",
      "-moz-box-sizing": "border-box",
      "box-sizing": "border-box"
    },
    "body": {
      "width": "8.5in",
      "height": "11in",
      "margin": "0",
      "padding": "0"
    },
    ".page": {
      "page-break-after": "always"
    },
    ".page-content": {
      "position": "relative",
      "width": "8.125in",
      "height": "10.625in",
      "left": "0.1875in",
      "top": "0.1875in",
      "background-color": "rgba(0,0,0,0.2)"
    },
    ".text": {
      "position": "relative",
      "left": "20px",
      "top": "20px",
      "width": "6in",
      "font-family": "sans-serif",
      "font-size": "30px"
    },
    "#return-address-window": {
      "position": "absolute",
      "left": ".625in",
      "top": ".5in",
      "width": "3.25in",
      "height": ".875in",
      "background-color": "rgba(255,0,0,0.5)"
    },
    "#return-address-text": {
      "position": "absolute",
      "left": ".07in",
      "top": ".34in",
      "width": "2.05in",
      "height": ".44in",
      "background-color": "white",
      "font-size": ".11in"
    },
    "#recipient-address-window": {
      "position": "absolute",
      "left": ".625in",
      "top": "1.75in",
      "width": "4in",
      "height": "1in",
      "background-color": "rgba(255,0,0,0.5)"
    },
    "#recipient-address-text": {
      "position": "absolute",
      "left": ".07in",
      "top": ".05in",
      "width": "2.92in",
      "height": ".9in",
      "background-color": "white"
    }}
  ',
  '
    <div class="page">
      <div class="page-content">
        <div class="text" style="top: 3in">
          Safe content area.  macro example: {{macro}}
        </div>
      </div>
      <div id="return-address-window">
        <div id="return-address-text">
          The Return Address will be printed here. The red area will be visible through the envelope window.
        </div>
      </div>
      <div id="recipient-address-window">
        <div id="recipient-address-text">
          The Recipients Address will be printed here. The red area will be visible through the envelope window.
        </div>
      </div>
    </div>
  '
);