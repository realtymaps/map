app = require '../app.coffee'
_ = require 'lodash'

app.service 'rmapsMailTemplateTypeService', ($log, rmapsMailPdfService) ->

  _categoryLists = {}
  _meta =
    'basicLetter':
      content: require('../../html/includes/mail/letterTemplates/blank-letter-template.jade')()
      name: "Blank Letter"
      thumb: "/assets/base/template_img.png"
      category: 'letter'

    'adjacentPropertyOwnerLetter':
      content: require('../../html/includes/mail/letterTemplates/adjacent-property-owner-template.jade')()
      name: "Adjacent Property Owner Letter"
      thumb: "/assets/base/template_img.png"
      category: 'letter'

    'introLetter':
      content: require('../../html/includes/mail/letterTemplates/intro-letter-template.jade')()
      name: "Intro / No Obligation Letter"
      thumb: "/assets/base/template_img.png"
      category: 'letter'

    'inquiryNoBroker':
      content: require('../../html/includes/mail/letterTemplates/inquiry-template.jade')()
      name: "Inquiry No Broker"
      thumb: "/assets/base/template_img.png"
      category: 'letter'

    'aggressiveInquiryNoBroker':
      content: require('../../html/includes/mail/letterTemplates/aggressive-inquiry-template.jade')()
      name: "Aggressive Inquiry No Broker"
      thumb: "/assets/base/template_img.png"
      category: 'letter'

    'inquirySinglePartyShortTermListing':
      content: require('../../html/includes/mail/letterTemplates/inquiry-single-party-short-term-listing-template.jade')()
      name: "Inquiry Short Term Listing"
      thumb: "/assets/base/template_img.png"
      category: 'letter'

    'socialMediaServices':
      content: require('../../html/includes/mail/letterTemplates/social-media-template.jade')()
      name: "Social Media"
      thumb: "/assets/base/template_img.png"
      category: 'letter'

    'saleOfRental':
      content: require('../../html/includes/mail/letterTemplates/sale-of-rental-template.jade')()
      name: "Sale of Rental"
      thumb: "/assets/base/template_img.png"
      category: 'letter'

    'sellerValuableAsset':
      content: require('../../html/includes/mail/letterTemplates/seller-valuable-asset-template.jade')()
      name: "Seller - Home is a Valuable Asset"
      thumb: "/assets/base/template_img.png"
      category: 'letter'

    'lookingForSellers':
      content: require('../../html/includes/mail/letterTemplates/looking-for-sellers-template.jade')()
      name: "Looking for Interested Sellers"
      thumb: "/assets/base/template_img.png"
      category: 'letter'

    'topOfMind':
      content: require('../../html/includes/mail/letterTemplates/top-of-mind-template.jade')()
      name: "Top of Mind Letter"
      thumb: "/assets/base/template_img.png"
      category: 'letter'

    'thinkingOfMoving':
      content: require('../../html/includes/mail/letterTemplates/thinking-of-moving-template.jade')()
      name: "Thinking of Moving Letter"
      thumb: "/assets/base/template_img.png"
      category: 'letter'

    'fsbo':
      content: require('../../html/includes/mail/letterTemplates/fsbo-template.jade')()
      name: "FSBO Letter"
      thumb: "/assets/base/template_img.png"
      category: 'letter'

  _buildCategoryLists = () ->
    _categoryLists = {}
    _categoryLists['all'] = []
    for templateType of _meta
      _categoryLists[_meta[templateType].category] = [] unless _meta[templateType].category of _categoryLists
      obj =
        name: _meta[templateType].name
        thumb: _meta[templateType].thumb
        category: _meta[templateType].category
        type: templateType

      _categoryLists['all'].push obj
      _categoryLists[_meta[templateType].category].push obj

    # since pdfs are, themselves, categorically a template type, retrieve them and include them here 
    rmapsMailPdfService.getAsCategory()
    .then (pdfs) ->
      _appendCategoryList 'pdf', pdfs


  _getTypeNames = () ->
    return Object.keys _meta

  # sending the hardcoded values by now until we get categories fleshed out.  This will need to be smarter and dynamic later
  # TODO: make _getCategories dynamic, MAPD-735 partly contributes
  _getCategories = () ->
    return [
      ['all', 'All Templates']
      ['letter', 'Letters']
      ['postcard', 'Postcards']
      ['pdf', 'Uploaded PDFs']
    ]

  _getMeta = () ->
    return _meta

  _getCategoryLists = () ->
    return _categoryLists

  _appendCategoryList = (type, list) ->
    if !(type of _categoryLists)
      _categoryLists[type] = []

    # nestle the items within maintenence structs as appropriate
    for item in list
      _categoryLists['all'].push item
      _categoryLists[type].push item
      if !(item.type of _meta)
        _meta[item.type] = {}
      _meta[item.type].content = item.type
      _meta[item.type].category = 'pdf'
      _meta[item.type].thumb = '/assets/base/template_pdf_img.png'

  _removePdf = (pdfType) ->
    _categoryLists['all'] = _.remove _categoryLists['all'], (obj) ->
      obj.type != pdfType
    _categoryLists['pdf'] = _.remove _categoryLists['pdf'], (obj) ->
      obj.type != pdfType
    delete _meta[pdfType]
    _getCategoryLists()


  _buildCategoryLists()

  #### public
  getTypeNames: _getTypeNames

  getMeta: _getMeta

  getCategories: _getCategories

  getCategoryLists: _getCategoryLists
  appendCategoryList: _appendCategoryList
  removePdf: _removePdf

  getMailContent: (type) ->
    _meta[type].content

  getCategoryFromType: (type) ->
    _meta[type].category

  getDefaultHtml: () ->
    _meta['basicLetter'].content
