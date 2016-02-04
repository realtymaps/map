testLetterMarkup = """
<div class="letter-page"><div class="letter-page-content-text"><span class="fontSize18">testing markup with a {{goodmacro}} and a {{badmacro}}.</span></div></div>
"""

describe 'rmapsMacro directive tests', ->

  @scope = @compile = @document = {}


  beforeEach ->
    angular.mock.module('rmapsMapApp')

    inject (_$compile_, _$rootScope_, _$document_) =>
      @document = _$document_[0]
      @compile = _$compile_
      @rootScope = _$rootScope_
      @scope = @rootScope.$new()
      @scope.macros =
        address: '{{address}}'
        macro: '{{macro}}'
      @scope.markup = testLetterMarkup
      _element = angular.element '<div rmaps-macro-helper ng-model="markup"></div>'
      @element = @compile(_element)(@scope)


  describe 'rmapsMacroHelper', ->

    it 'should have good markup', ->
      expect(@element).to.be.ok

    it 'should validate macros', ->
      goodMacro = "{{address}}"
      badMacro = "{{faddress}}"

      expect(@scope.validateMacro(goodMacro)).to.be.true
      expect(@scope.validateMacro(badMacro)).to.be.false

    it 'setMacroClass should work', ->
      macroText01 = @document.createTextNode('{{macro}}')
      macroParent01 = @document.createElement('span')
      macroParent01.appendChild(macroText01)
      goodMacro01 = @document.createElement('span')
      goodMacro01.appendChild(macroParent01)

      macroText02 = @document.createTextNode('{{macro}}')
      macroParent02 = @document.createElement('span')
      macroParent02.classList.add('macro-display-error')
      macroParent02.appendChild(macroText02)
      goodMacro02 = @document.createElement('span')
      goodMacro02.appendChild(macroParent02)

      macroText03 = @document.createTextNode('{{foo}}')
      macroParent03 = @document.createElement('span')
      macroParent03.appendChild(macroText03)
      badMacro = @document.createElement('span')
      badMacro.appendChild(macroParent03)

      goodExpectedInnerHTML = '<span class="macro-display">{{macro}}</span>'
      badExpectedInnerHTML = '<span class="macro-display-error">{{foo}}</span>'

      @scope.setMacroClass(goodMacro01.childNodes[0])
      expect(goodMacro01.innerHTML).to.equal goodExpectedInnerHTML

      @scope.setMacroClass(goodMacro02.childNodes[0])
      expect(goodMacro02.innerHTML).to.equal goodExpectedInnerHTML

      @scope.setMacroClass(badMacro.childNodes[0])
      expect(badMacro.innerHTML).to.equal badExpectedInnerHTML

    it 'isMacroNode should identify macro span by class (does not validate macro)', ->
      macroText01 = @document.createTextNode('{{macro}}')
      goodMacro01 = @document.createElement('span')
      goodMacro01.appendChild(macroText01)
      goodMacro01.classList.add 'macro-display'

      macroText02 = @document.createTextNode('{{invalidmacro}}')
      goodMacro02 = @document.createElement('span')
      goodMacro02.appendChild(macroText02)
      goodMacro02.classList.add 'macro-display-error'

      macroText03 = @document.createTextNode('{{invalidmacro}}')
      badMacro01 = @document.createElement('span')
      badMacro01.appendChild(macroText03)
      badMacro01.classList.add 'no-macro-class'

      expect(@scope.isMacroNode(goodMacro01)).to.be.true
      expect(@scope.isMacroNode(goodMacro02)).to.be.true
      expect(@scope.isMacroNode(badMacro01)).to.be.false

    # skipped since DOMParser instances return null here
    xit 'should walk dom tree', ->
      _doc = new DOMParser().parseFromString(testLetterMarkup, 'text/html')

      _test = (n) ->
        # need to test something
        return true

      _process = (n) ->
        # need to process something

      @scope.walk _doc, 'childNodes', _test, _process

    # skipped since DOMParser instances return null here
    xit 'convertMacros should work', ->
      @scope.macros =
        goodmacro: '{{goodmacro}}'
      postProcessedHtml = '<div class="letter-page"><div class="letter-page-content-text"><span class="fontSize18">testing markup with a <span class="macro-display">{{goodmacro}}</span> and a <span class="macro-display-error">{{badmacro}}</span>.</span></div></div>'
      expect(@scope.convertMacros()).to.equal postProcessedHtml

    # skipped since the rangy setStart doesn't seem to be happy with my textnode in test env
    xit 'macroFilter should work', ->
      @scope.macros =
        goodmacro1: '{{goodmacro1}}'
        goodmacro2: '{{goodmacro2}}'

      # get a rangy-compatible selection
      # with html:
      # selHtml = '<span>Testing a padded <span class="macro-display">{{goodmacro1}}      </span> and an altered bad macro <span class="macro-display-error">{{goodmacro2}}</span></span>'
      sel = rangy.getSelection()
      expectedHtml = '<span>Testing a padded <span class="macro-display">{{goodmacro1}}</span> and an altered bad macro <span class="macro-display">{{goodmacro2}}</span></span>'
      expect(@scope.macroFilter(sel)).to.equal expectedHtml

    # skipped since the rangy setStart doesn't seem to be happy with my textnode in test env
    xit 'convertMacrosInSpan should convert macros', ->
      # create html span & 'textnode' for good macro
      goodElement = angular.element '<span>Some test text with a {{macro}}.</span>'
      goodOffset = 23
      goodMacro = "{{macro}}"

      # create html span & 'textnode' for bad macro
      badElement = angular.element '<span>Some test text with a {{badmacro}}.</span>'
      badOffset = 23
      badMacro = "{{badmacro}}"

      exchange = false
      goodExpectedInnerHTML = '<span>Some test text with a <span class="macro-display">{{macro}}</span></span>'
      badExpectedInnerHTML = '<span>Some test text with a <span class="macro-display-error">{{badmacro}}</span></span>'

      @scope.convertMacrosInSpan(goodElement, goodOffset, goodMacro, exchange)
      @scope.convertMacrosInSpan(badElement, badOffset, badMacro, exchange)

      expect(goodElement.innerHTML).to.equal goodExpectedInnerHTML
      expect(badElement.innerHTML).to.equal badExpectedInnerHTML
