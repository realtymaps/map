app = require '../app.coffee'
_ = require 'lodash'




app.service 'rmapsMailTemplateTypeService', ($log) ->

  #### containers for detailed operators, getters for content, 
  _defaultHtml =
    'basicLetter':
      content: require('../../html/includes/mail/basic-letter-template.jade')()

      # document level adjustments we want to make for wysiwyg based on template type
      # add/remove special things into wysiwyg that we don't want to put in the original template, and not show up in letter
      # (requires explicit dom manipulation to set inner text, etc)
      # e.g. let's put informative text into the "return-address-window" element indicating where address will go
      addTemporaryHtml: (doc) ->
        # temporary indicator-text for address windows already placed in template

      removeTemporaryHtml: (doc) ->
        for clearDiv in ['return-address-window', 'recipient-address-window']
          div = doc.getElementById(clearDiv) || {childNodes: []}
          for child in div.childNodes
            child.remove()
        tmpBody = doc.createElement 'div'
        tmpBody.appendChild doc.children[0]
        tmpBody.innerHTML

  _defaultFinalStyle =
    'basicLetter':
      content: require '../../styles/mailTemplates/basic-letter/lob.styl'


  #### a kindof meta data for available template types and categorization
  _getTemplateTypeNames = () ->
    return Object.keys defaultHtml


  #### public
  getTemplateTypeNames: _getTemplateTypeNames

  getDefaultHtml: (type) ->
    return _defaultHtml[type].content

  getDefaultFinalStyle: (type) ->
    return _defaultFinalStyle[type].content
