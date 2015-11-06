testLetterMarkup = """
<div class="letter-page"><div class="letter-page-content-text"><span class="fontSize18">testing markup with a {{goodmacro}} and a {{badmacro}}.</span></div></div>
"""

describe 'rmapsMacro directive tests', ->

  @scope = @compile = @document = {}


  beforeEach ->
    console.log "#### beforeEach()"
    angular.mock.module('rmapsMapApp')
  
    inject ($compile, $rootScope, $document) =>
      @document = $document[0]
      @compile = $compile
      @$rootScope = $rootScope
      @scope = @$rootScope.$new()

      # @scope.markup = testLetterMarkup
      # @basicElement = @compile(angular.element("<div rmaps-macro-helper ng-model='markup'></div>"))(@scope)
      # @scope.$digest()


      # @getElement = () ->
      #   console.log "#### getElement()"
      #   console.log "testLetterMarkup:"
      #   console.log testLetterMarkup
      #   console.log "scope:"
      #   console.log @scope

      #   @scope.markup = testLetterMarkup
      #   element = @compile(angular.element("<div rmaps-macro-helper ng-model='markup'></div>"))(@scope)
      #   @scope.$digest()
      #   return element

  describe 'rmapsMacroHelper', ->
    xit 'should validate macros', ->
      @scope.macros =
        address: '{{address}}'
      goodMacro = "{{address}}"
      badMacro = "{{faddress}}"

      expect(@scope.validateMacro(goodMacro)).to.be.true
      expect(@scope.validateMacro(badMacro)).to.be.false

    xit 'should walk dom tree', ->
      _doc = new DOMParser().parseFromString(testLetterMarkup, 'text/html')

      _test = (n) ->
        # need to test something
        return true

      _process = (n) ->
        # need to process something

      @scope.walk _doc, 'childNodes', _test, _process

    xit 'convertMacrosInSpan should convert macros', ->
      @scope.macros =
        macro: '{{macro}}'

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


    xit 'isMacroNode should identify macro span class', ->
      goodMacroElement01 = angular.element '<span class="macro-display">{{goodmacro01}}</span>'
      goodMacroElement02 = angular.element '<span class="macro-display-error">{{goodmacro02}}</span>'
      badMacroElement01 = angular.element '<span class="not-macro-display">{{badmacro01}}</span>'
      expect(@scope.isMacroNode(goodMacroElement01)).to.be.true
      expect(@scope.isMacroNode(goodMacroElement02)).to.be.true
      expect(@scope.isMacroNode(badMacroElement01)).to.be.false

    xit 'setMacroClass should work', ->
      @scope.macros =
        macro: '{{macro}}'
      goodTextElement01 = angular.element '<span>{{macro}}</span>'
      goodTextElement02 = angular.element '<span class="macro-display-error">{{macro}}</span>'
      badTextElement = angular.element '<span>{{foo}}</span>'
      goodExpectedInnerHTML = '<span class="macro-display">{{macro}}</span>'
      badExpectedInnerHTML = '<span class="macro-display-error">{{foo}}</span>'

      expect(@scope.setMacroClass(goodTextElement01)).to.equal goodExpectedInnerHTML
      expect(@scope.setMacroClass(goodTextElement02)).to.equal goodExpectedInnerHTML
      expect(@scope.setMacroClass(badTextElement)).to.equal badExpectedInnerHTML
      # some missing cases concerning logic for parent vs text node

    xit 'convertMacros should work', ->
      @scope.macros =
        goodmacro: '{{goodmacro}}'
      postProcessedHtml = '<div class="letter-page"><div class="letter-page-content-text"><span class="fontSize18">testing markup with a <span class="macro-display">{{goodmacro}}</span> and a <span class="macro-display-error">{{badmacro}}</span>.</span></div></div>'

      expect(@scope.convertMacros()).to.equal postProcessedHtml

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


    xit 'should have good markup', ->
      expect(@basicElement).to.be.ok
