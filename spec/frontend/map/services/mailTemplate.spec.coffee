campaignFixture = require '../fixtures/mailCampaign.json'

describe 'mailTemplate service', ->

  beforeEach ->
    angular.mock.module('rmapsMapApp')

    inject (rmapsMailTemplateService) =>
      @type = 'basicLetter'
      @template = rmapsMailTemplateService

  it 'passes sanity check', ->
    expect(@template).to.be.ok
    expect(@template.getCampaign().content).to.not.exist
    @template.setTemplateType(@type)
    expect(@template.getCampaign().content).to.have.length.above 0

  describe 'service members', ->

    it 'returns correct defaults', ->
      expected =
        id: null
        auth_user_id: null
        lob_batch_id: null
        name: 'New Mailing'
        count: 0
        status: 'pending'
        content: null
        template_type: ''
        lob_content: null
        sender_info: null
        recipients: []
        submitted: null

      actual = @template.getCampaign()
      expect(actual).to.eql expected

    it 'returns correct lob entity', ->
      lobRecipients = [
        name: 'Current Resident'
        address_line1: '1775 Gulf Shore Blvd S'
        address_line2: ''
        address_city: 'Naples'
        address_state: 'FL'
        address_zip: '34102-7561'
      ,
        name: 'Current Resident'
        address_line1: '175 16th Ave S'
        address_line2: ''
        address_city: 'Naples'
        address_state: 'FL'
        address_zip: '34102-7443'
      ]

      lobFrom =
        company: null
        address_line1: '791 10th St. S'
        address_line2: null
        address_city: 'Naples'
        address_state: 'FL'
        address_zip: '34102'
        phone: null
        email: 'mailtest@realtymaps.com'
        name: 'Fname Lname'

      @template.setCampaign(campaignFixture)
      actual = @template.getLobData()

      expect(actual.campaign).to.eql campaignFixture
      expect(actual.file).to.contain '<div class="letter-page"><p>Content</p></div></body>'
      expect(actual.recipients).to.eql lobRecipients
      expect(actual.from).to.eql lobFrom

    it 'returns correct template category', ->
      @template.setCampaign(campaignFixture)
      category = @template.getCategory()
      expect(category).to.eql 'letter'

