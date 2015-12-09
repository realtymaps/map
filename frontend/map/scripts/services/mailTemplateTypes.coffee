app = require '../app.coffee'
_ = require 'lodash'

c = require('../../html/includes/mail/basic-letter-template.jade')()

console.log "\n\n\ncontent:"
console.log c

app.service 'rmapsMailTemplateTypeService', ($log) ->

  _meta =
    'basicLetter':
      content: c
      #style: require '../../styles/mailTemplates/basic-letter/lob.styl'

      # document level adjustments we want to make for wysiwyg based on template type
      # add/remove special things into wysiwyg that we don't want to put in the original template, and not show up in letter
      # (requires explicit dom manipulation to set inner text, etc)
      # e.g. let's put informative text into the "return-address-window" element indicating where address will go
      addTemporaryHtml: (doc) ->
        # temporary indicator-text for address windows already placed in template

      removeTemporaryHtml: (doc) ->
        # # clean out all indicator-text or other non-final artificats
        # for clearDiv in ['return-address-window', 'recipient-address-window']
        #   div = doc.getElementById(clearDiv) || {childNodes: []}
        #   for child in div.childNodes
        #     child.remove()
        # tmpBody = doc.createElement 'div'
        # tmpBody.appendChild doc.children[0]
        # tmpBody.innerHTML

      name: "Basic Letter #1"
      thumb: "/assets/base/template_img.png"
      category: 'letter'

    'tempLetter02':
      name: "Basic Letter #2"
      thumb: "/assets/base/template_img.png"
      category: 'letter'

    'tempLetter03':
      name: "Basic Letter #3"
      thumb: "/assets/base/template_img.png"
      category: 'letter'

    'tempPostcard01':
      name: "Basic Postcard #1"
      thumb: "/assets/base/template_img.png"
      category: 'postcard'

    'tempPostcard02':
      name: "Basic Postcard #2"
      thumb: "/assets/base/template_img.png"
      category: 'postcard'


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
      ['custom', 'Custom']
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

  getDefaultHtml: (type) ->
    _meta[type].content

  # getDefaultFinalStyle: (type) ->
  #   _meta[type].style

  # setUp: (type, doc) ->
  #   _meta[type].addTemporaryHtml(doc)

  # tearDown: (type, doc) ->
  #   _meta[type].removeTemporaryHtml(doc)
