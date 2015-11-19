

describe 'mailTemplateType service', ->

  beforeEach ->
    angular.mock.module('rmapsMapApp')
  
    inject (rmapsMailTemplateTypeService) =>
      @svc = rmapsMailTemplateTypeService
      # @type = 'basicLetter'
      # @template = new rmapsMailTemplate(@type)
      # @template.mailCampaign.content = testBasicLetterMarkup
      # @template.style = 'body {width: 8.5in; height: 11in;}'

  describe 'service members', ->
    it "tests ok svc", ->
      @svc.should.be.ok

    it "makes sure structure sizes jive", ->
      expect(@svc.getTemplateTypeNames)
    #   @template.should.be.ok
    #   expect(@template.type).to.eql @type

    # it 'test createPreviewHtml', ->
    #   expectedPreviewMarkup = '<html><head><title>New Mailing</title><style>body {width: 8.5in; height: 11in;}body {border: 1px solid black;}</style>'+
    #   '</head><body><div class="letter-page"><div id="recipient-address-window"><div>placeholder1</div></div><div id="return-address-window"><div>placeholder2</div></div>'+
    #   '<div class="letter-page-content-text"><span class="fontSize18">testing markup with a {{goodmacro}} and a {{badmacro}}.</span></div></div></body></html>'
    #   expect(@template._createPreviewHtml()).to.equal expectedPreviewMarkup

    # xit 'test createLobHtml', ->
    #   # fails because DOMParser is returning null 
    #   # @template._createLobHtml()

