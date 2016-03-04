app = require '../app.coffee'
_ = require 'lodash'

app.service 'rmapsMailTemplateTypeService', ($log) ->

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


  _getTypeNames = () ->
    return Object.keys _meta

  # sending the hardcoded values by now until we get categories fleshed out.  This will need to be smarter and dynamic later
  # TODO: make _getCategories dynamic, MAPD-735 partly contributes
  _getCategories = () ->
    return [
      ['all', 'All Templates']
      ['letter', 'Letters']
      ['postcard', 'Postcards']
      ['favorite', 'Favorites']
      # ['custom', 'Custom']
    ]

  _getMeta = () ->
    return _meta

  _getCategoryLists = () ->
    t = {}
    t['all'] = []
    for templateType of _meta
      t[_meta[templateType].category] = [] unless _meta[templateType].category of t
      obj =
        name: _meta[templateType].name
        thumb: _meta[templateType].thumb
        category: _meta[templateType].category
        type: templateType

      t['all'].push obj
      t[_meta[templateType].category].push obj
    t

  #### public
  getTypeNames: _getTypeNames

  getMeta: _getMeta

  getCategories: _getCategories

  getCategoryLists: _getCategoryLists

  getHtml: (type) ->
    _meta[type].content

  getCategoryFromType: (type) ->
    _meta[type].category

  getDefaultHtml: () ->
    _meta['basicLetter'].content
