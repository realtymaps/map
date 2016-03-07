app = require '../app.coffee'
_ = require 'lodash'

app.service 'rmapsMailTemplateTypeService', ($log) ->

  _categoryLists = {}
  _meta =
    'basicLetter':
      content: require('../../html/includes/mail/basic-letter-template.jade')()
      name: "Basic Letter #1"
      thumb: "/assets/base/template_img.png"
      category: 'letter'

    'introductionLetter':
      content: require('../../html/includes/mail/introduction-letter-template.jade')()
      name: "Introduction Letter"
      thumb: "/assets/base/template_img.png"
      category: 'letter'

    'prospectingLetter':
      content: require('../../html/includes/mail/prospecting-letter-template.jade')()
      name: "Prospecting Letter"
      thumb: "/assets/base/template_img.png"
      category: 'letter'

    'neighborhoodFarmingLetter':
      content: require('../../html/includes/mail/neighborhood-farming-letter-template.jade')()
      name: "Neighborhood Farming Letter"
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
      # ['favorite', 'Favorites']
      # ['custom', 'Custom']
    ]

  _getMeta = () ->
    return _meta

  _getCategoryLists = () ->
    return _categoryLists

  _appendCategoryList = (type, list) ->
    if !(type of _categoryLists)
      _categoryLists[type] = []

    # angular.extend _categoryLists['all'], list
    # angular.extend _categoryLists[type], list
    console.log "\n\nlist:"
    console.log "#{JSON.stringify(list, null, 2)}"
    for item in list
      _categoryLists['all'].push item
      _categoryLists[type].push item
      if !(item.type of _meta)
        _meta[item.type] = {}
      _meta[item.type].content = type
      _meta[item.type].category = 'pdf'

  _buildCategoryLists()

  #### public
  getTypeNames: _getTypeNames

  getMeta: _getMeta

  getCategories: _getCategories

  getCategoryLists: _getCategoryLists
  appendCategoryList: _appendCategoryList

  getHtml: (type) ->
    _meta[type].content

  getCategoryFromType: (type) ->
    _meta[type].category

  getDefaultHtml: () ->
    _meta['basicLetter'].content
