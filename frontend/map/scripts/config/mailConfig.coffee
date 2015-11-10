app = require '../app.coffee'


app.config ($provide) ->
  $provide.decorator 'taOptions', ['$log', '$document', 'taRegisterTool', '$delegate', '$timeout', 'textAngularManager', 'rmapsMainOptions',
  ($log, $document, taRegisterTool, taOptions, $timeout, textAngularManager, rmapsMainOptions) ->

    # helps HTML5 compatibility, which uses css instead of deprecated tags like <font>
    $document[0].execCommand('styleWithCSS', false, true)

    for fontSize in [['fontSize10', '10pt'],['fontSize12', '12pt'],['fontSize14', '14pt'],['fontSize16', '16pt'],['fontSize18', '18pt'],['fontSize20', '20pt']]
      do (fontSize) ->
        taRegisterTool fontSize[0],
          buttontext: fontSize[1],
          class: "btn btn-white",
          display: "<label> #{fontSize[1]}"
          action: () ->
            classApplier = rangy.createClassApplier fontSize[0],
              tagNames: ["*"],
              normalize: true
            classApplier.toggleSelection()
          activeState: (el) ->
            sel = rangy.getSelection()
            return sel.nativeSelection.focusNode.parentNode.classList.contains fontSize[0]

    for font in ['Georgia','Gill Sans','Times New Roman','Helvetica']
      do (font) ->
        nospace = font.replace(/ /g,'')
        maybeQuoted = if / /.test(font) then "'#{font}'" else font
        r = new RegExp "font-family: #{maybeQuoted}"
        taRegisterTool "font#{nospace}",
          buttontext: font
          class: 'btn btn-text'
          display: "<label> #{font}"
          action: () ->
            this.$editor().wrapSelection 'fontName', font
          activeState: (el) ->
            return el[0].attributes.style?.textContent? && r.test(el[0].attributes.style.textContent)

    for color in ['Black','Blue','Green','Red','Yellow','White']
      do (color) ->
        taRegisterTool "text#{color}",
          buttontext: color
          class: "btn btn-circle color-#{color.toLowerCase()}"
          action: () ->
            this.$editor().wrapSelection 'forecolor', color.toLowerCase()
          activeState: (el) ->
            node = el[0]
            while node.parentNode? and not node.parentNode.classList.contains 'letter-page-content-text'
              r = new RegExp "color: #{color.toLowerCase()}"
              if node.attributes.style?.textContent? && r.test(node.attributes.style.textContent)
                return true
              node = node.parentNode
            return false

    return taOptions
  ]