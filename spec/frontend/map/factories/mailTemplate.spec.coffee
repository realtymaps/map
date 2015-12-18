testBasicLetterMarkup = """
<div class="letter-page" style="width: 8.5in; height: 11in;"><div id="recipient-address-window"><div>placeholder1</div></div><div id="return-address-window"><div>placeholder2</div></div><div class="letter-page-content-text"><span class="fontSize18">testing markup with a {{goodmacro}} and a {{badmacro}}.</span></div></div>
"""

describe 'mailTemplate factory', ->

  beforeEach ->
    angular.mock.module('rmapsMapApp')
  
    inject (rmapsMailTemplate) =>
      @type = 'basicLetter'
      @template = new rmapsMailTemplate(@type)
      @template.mailCampaign.content = testBasicLetterMarkup

  describe 'templateObj', ->
    it "tests valid basicLetter", ->
      @template.should.be.ok
      expect(@template.type).to.eql @type

    it 'test createPreviewHtml', ->
      expect(@template._createPreviewHtml()).to.contain 'body {border: 1px solid black;}'
      expect(@template._createPreviewHtml()).to.contain '<div class="letter-page" style="width: 8.5in; height: 11in;">'

    it 'test createLobHtml', ->
      expect(@template._createLobHtml()).to.not.contain 'body {border: 1px solid black;}'
      expect(@template._createLobHtml()).to.contain '<div class="letter-page" style="width: 8.5in; height: 11in;">'

