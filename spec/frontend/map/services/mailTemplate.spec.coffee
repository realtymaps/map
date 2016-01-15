testBasicLetterMarkup = """
<div class="letter-page" style="width: 8.5in; height: 11in;"><div id="recipient-address-window"><div>placeholder1</div></div><div id="return-address-window"><div>placeholder2</div></div><div class="letter-page-content-text"><span class="fontSize18">testing markup with a {{goodmacro}} and a {{badmacro}}.</span></div></div>
"""

describe 'mailTemplate service', ->

  beforeEach ->
    angular.mock.module('rmapsMapApp')

    inject (rmapsMailTemplate) =>
      @type = 'basicLetter'
      @template = rmapsMailTemplate

  describe 'templateObj', ->
    it "tests valid basicLetter", ->
      expect(@template).to.be.ok
      expect(@template.getCampaign().content).to.not.exist
      @template.setTemplateType(@type)
      expect(@template.getCampaign().content).to.have.length.above 0

    it 'returns createPreviewHtml', ->
      @template.setTemplateType(@type)
      expect(@template.createPreviewHtml()).to.contain 'body {border: 1px solid black;}'
      expect(@template.createPreviewHtml()).to.contain '<div class="letter-page">'

    it 'returns createLobHtml', ->
      @template.setTemplateType(@type)
      expect(@template.createLobHtml()).to.not.contain 'body {border: 1px solid black;}'
      expect(@template.createLobHtml()).to.contain '<div class="letter-page">'
