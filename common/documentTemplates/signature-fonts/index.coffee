_ = require 'lodash'

###
  Data for each font included via this file is a base64 encoding of files downloaded from Font Squirrel
  (http://www.fontsquirrel.com/).  Before base64 encoding, some of the files were converted from otf to ttf.

  As of the date they were downloaded, each of the fonts used to generate this file was asserted to be licensed
  for use in ALL of the following ways:
    * Commercial Desktop Use - this free license allows you to create commercial graphics and documents.
    * Ebooks and PDFs - this free license allows you to embed the fonts in eBooks and portable documents.
    * Applications - this free license allows you to embed the fonts in applications and software.

  In addition, the license file included in each downloaded archive was checked for license terms conflicting
  with the intended use here, and nothing conflicting was found.  The licenses associated with the archives are
  included as the "license" string property of each font included here.
  
  Inclusion in this file is not intended to be distribution of the source font -- we are embedding the font data
  within our application.  If you extract any of the fonts here for use in any way, you are still bound by the
  terms of the licenses associated with those fonts.
###

baseFont =
  signatureSize: 22
  angle: 0
  xOffset: 10

module.exports =
  "print font 1":               _.extend {}, baseFont, require("./daniel/daniel.coffee")
  "print font 1 (bold)":        _.extend {}, baseFont, require("./daniel/danielbd.coffee")
  "print font 1 (bolder)":      _.extend {}, baseFont, require("./daniel/Daniel-Black.coffee")
  "print font 2":               _.extend {}, baseFont, require("./bilbo/Bilbo-Regular.coffee")
  "print font 2 (fancy caps)":  _.extend {}, baseFont, require("./bilbo/BilboSwashCaps-Regular.coffee")
  "print font 3":               _.extend {}, baseFont, require("./jenna-sue/JennaSue.coffee")
  "script font 1":              _.extend {}, baseFont, require("./kristi/Kristi.coffee")
  "script font 2":              _.extend {}, baseFont, require("./allura/Allura-Regular.coffee")
