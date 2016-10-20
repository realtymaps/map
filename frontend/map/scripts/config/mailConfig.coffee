###globals angular###
app = require '../app.coffee'

rangy = require 'rangy' #rangy is a global in textangular
require 'rangy/lib/rangy-classapplier.js'


app.config ($provide) ->
  $provide.decorator 'taOptions', ($log, $document, taRegisterTool, $delegate, $timeout, textAngularManager, taTools, rmapsMainOptions, taSelection) ->

    # helps HTML5 compatibility, which uses css instead of deprecated tags like <font>
    $document[0].execCommand('styleWithCSS', false, true)

    # $delegate.disableSanitizer = true
    $delegate.forceTextAngularSanitize = false
    if !rangy.createClassApplier?
      rangy.init()
    fontToolElements = {}
    fontSizeAppliers = {}
    fontSizeList = [['fontSize10', '10pt'],['fontSize12', '12pt'],['fontSize14', '14pt'],['fontSize16', '16pt'],['fontSize18', '18pt'],['fontSize20', '20pt']]
    for fontSize in fontSizeList
      do (fontSize) ->
        fontSizeApplier = rangy.createClassApplier fontSize[0], {normalize: true}
        fontSizeAppliers[fontSize[0]] = fontSizeApplier

        tool = taRegisterTool fontSize[0],
          buttontext: fontSize[1],
          class: "btn btn-white",
          display: "<label> #{fontSize[1]}"
          action: () ->
            fontSizeApplier.toggleSelection()
            sel = rangy.getNativeSelection()
            r = sel.getRangeAt(0)

            $log.debug "\n\n### sel:"
            $log.debug sel
            $log.debug "### r:"
            $log.debug r

            $log.debug "### sel.anchorOffset: #{sel.anchorOffset}"
            $log.debug "### sel.focusOffset:  #{sel.focusOffset}"
            $log.debug "### sel.extentOffset: #{sel.extentOffset}"
            $log.debug "### sel.baseOffset:   #{sel.baseOffset}"
            $log.debug "### sel.rangeCount:   #{sel.rangeCount}"
            $log.debug "### r.startOffset:    #{r.startOffset}"
            $log.debug "### r.endOffset:      #{r.endOffset}"
            $log.debug "### range offset diff:#{r.endOffset - r.startOffset}"

            # if a range of highlighted text is selected to change the font size...
            if (r.endOffset - r.startOffset) > 0
              classList = sel.focusNode.parentNode.classList

              angular.forEach classList, (el, idx) ->
                if /fontSize/.test(el) and el != fontSize[0]
                  fontSizeAppliers[el].toggleSelection()

            # if a caret is placed (no highlighted text) and typed text needs to reflect new font size...
            # (broken)
            else
              # this is the best (but failing) attempt:
              # span is created, but still unable to get the caret to register inside new blank element
              element = angular.element("<span class='#{fontSize[0]}'></span>")[0]
              #e = taSelection.insertHtml('', taSelection.container)
              r.insertNode(element)
              taSelection.setSelectionToElementEnd(element)
              element.focus()

            # doesn't seem to really do anything, but might be needed to get above to work
            $timeout () =>
              this.$editor().updateSelectedStyles(sel) # best (but failing) attempt to update toolbar buttons to correct active state
              this.$apply()
              this.$editor().$apply()


          activeState: (el) ->
            node = el[0]

            while node.parentNode? and not (node.parentNode.classList?.contains 'letter-page') and not /fontSize/.test(node.className)
              node = node.parentNode

            return node.classList?.contains fontSize[0]

          fontToolElements[fontSize[0]] = tool


    # these are tool definitions for currently excluded tools
    # for font in ['Georgia','Gill Sans','Times New Roman','Helvetica']
    #   do (font) ->
    #     nospace = font.replace(/ /g,'')
    #     maybeQuoted = if / /.test(font) then "'#{font}'" else font
    #     r = new RegExp "font-family: #{maybeQuoted}"
    #     taRegisterTool "font#{nospace}",
    #       buttontext: font
    #       class: 'btn btn-text'
    #       display: "<label> #{font}"
    #       action: () ->
    #         this.$editor().wrapSelection 'fontName', font
    #       activeState: (el) ->
    #         return el[0].attributes.style?.textContent? && r.test(el[0].attributes.style.textContent)

    # for color in ['Black','Blue','Green','Red','Yellow','White']
    #   do (color) ->
    #     taRegisterTool "text#{color}",
    #       buttontext: color
    #       class: "btn btn-circle color-#{color.toLowerCase()}"
    #       action: () ->
    #         this.$editor().wrapSelection 'forecolor', color.toLowerCase()
    #       activeState: (el) ->
    #         node = el[0]
    #         while node.parentNode? and not node.parentNode.classList.contains 'letter-page'
    #           r = new RegExp "color: #{color.toLowerCase()}"
    #           if node.attributes.style?.textContent? && r.test(node.attributes.style.textContent)
    #             return true
    #           node = node.parentNode
    #         return false

    return $delegate
