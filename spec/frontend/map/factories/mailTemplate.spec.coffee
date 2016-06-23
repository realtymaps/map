campaignFixture = require '../fixtures/mailCampaign.json'

describe 'mailTemplate service', ->

  beforeEach ->
    angular.mock.module('rmapsMapApp')

    inject (rmapsMailTemplateFactory) =>
      @type = 'basicLetter'
      @template = new rmapsMailTemplateFactory()

  it 'passes sanity check', ->
    expect(@template).to.be.ok
    expect(@template.campaign.content).to.not.exist
    @template.setTemplateType(@type)
    expect(@template.campaign.content).to.have.length.above 0

  describe 'factory members', ->

    it 'returns correct defaults', ->
      expected =
        id: null
        auth_user_id: null
        name: 'New Mailing'
        status: 'ready'
        content: null
        template_type: ''
        lob_content: null
        sender_info: null
        recipients: []
        aws_key: null
        project_id: null
        custom_content: false
        options:
          color: false

      actual = @template.campaign
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

      @template.campaign = campaignFixture
      expect(@template.campaign.content).to.contain '<div class="letter-page"><p>Content</p></div>'
      expect(@template.createLobHtml()).to.contain '<body class=\'letter-body\'><div class=\"letter-page\"><p>Content</p></div></body>'

    it 'returns correct template category', ->
      @template.campaign = campaignFixture
      category = @template.getCategory()
      expect(category).to.eql 'letter'

