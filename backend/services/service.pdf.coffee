PopplerDocument = require('poppler-simple').PopplerDocument
Buffer = require('buffer').Buffer
Promise = require 'bluebird'
request = require 'request'

getUrlPageCount = (url) ->
  console.log "getUrlPageCount()"
  # allocate a buffer for pdf packets to populate
  pdfbuffer = new Buffer('')

  return new Promise (resolve, reject) ->
    console.log "url: #{url}"
    request.get(url)
    .on('data', (chunk) ->
      console.log "chunk.length: #{chunk.length}"
      pdfbuffer = Buffer.concat([pdfbuffer, chunk])
    )
    .on('end', () ->
      console.log "request end..."
      console.log "pdf buffer length: #{pdfbuffer.length}"
      httpDoc = new PopplerDocument(pdfbuffer)
      console.log "resolving #{httpDoc.pageCount}"
      resolve(httpDoc.pageCount)
    )
    .on('error', (err) ->
      console.log "got err: #{err}"
      reject(err)
    )

getFilePageCount = (file) ->
  return new Promise (resolve, reject) ->
    try
      localDoc = new PopplerDocument(mylocalfile)
      resolve(localDoc.pageCount)
    catch err
      reject(err)


module.exports =
  getUrlPageCount: getUrlPageCount
  getFilePageCount: getFilePageCount