crypto = require 'crypto'


# I couldn't find any really good encryption simplification libs.  There were a couple that were close, but none
# that I considered good enough.  This is a good candidate for open-sourcing, as everything else I saw had flaws
# or limitations.

# TODO: add forbidBadIdeas option that will cause exceptions when a known bad practice is detected
#       http://web.cs.ucdavis.edu/~rogaway/papers/modes.pdf
#       http://csrc.nist.gov/groups/ST/toolkit/BCM/documents/ccm-ad1.pdf
# TODO: handle streaming input data
# TODO: option for streaming output data
# TODO: infer init vector size based on algo
# TODO: custom encoding functions/objects


class Encryptor

  constructor: (options) ->
    # copy over fields from options to instance
    {
      @textEncoding
      @keyEncoding
      @payloadEncoding
      @cipherKey
      @cipherAlgo
      @authenticationKey
      @authentication
      @initVectorSize
      @allowPredictableBytes
      @autoPadding
      @packPayload
      @unpackPayload
      @payloadDelimiter
    } = options


    # set some default values
    @textEncoding ?= 'utf8'
    @keyEncoding ?= 'hex'
    @payloadEncoding ?= 'base64'
    @cipherAlgo ?= 'AES-256-CTR'
    @initVectorSize ?= 16
    @payloadDelimiter ?= '$'
    @packPayload ?= (payloadData, encoding, delimiter) ->
      return [
        payloadData.iv.toString(encoding)
        payloadData.aad.toString(encoding)
        payloadData.data.toString(encoding)
        payloadData.auth.toString(encoding)
      ].join(delimiter)
    @unpackPayload ?= (payload, encoding, delimiter) ->
      pieces = payload.split(delimiter)
      return {
        iv: new Buffer(pieces[0], encoding)
        aad: new Buffer(pieces[1], encoding)
        data: new Buffer(pieces[2], encoding)
        auth: new Buffer(pieces[3], encoding)
      }

    # coerce keys to Buffers if necessary
    if @cipherKey && !Buffer.isBuffer(@cipherKey)
      @cipherKey = new Buffer(@cipherKey, @keyEncoding)
    if @authenticationKey && !Buffer.isBuffer(@authenticationKey)
      @authenticationKey = new Buffer(@authenticationKey, @keyEncoding)


  encrypt: (plainData, authData, initVector) ->

    if !@cipherKey?
      throw new Error('A cipher key is required')

    payloadData = {}

    if !Buffer.isBuffer(plainData)
      plainData = new Buffer(plainData, @textEncoding)

    if !initVector && @initVectorSize
      # usually, we just want the initVector to be generated fresh each time we encrypt
      try
        payloadData.iv = crypto.randomBytes(@initVectorSize)
      catch err
        if !@allowPredictableBytes
          throw err
        payloadData.iv = crypto.pseudoRandomBytes(@initVectorSize)
    else if Buffer.isBuffer(initVector)
      # but we do allow externally-generated initVector buffers
      payloadData.iv = initVector
    else if initVector
      # or things we can turn it into a buffer
      payloadData.iv = new Buffer(initVector, @keyEncoding)
    else
      payloadData.iv = new Buffer(0)

    # 2 different factory calls to make, depending on whether we're using an initVector
    if payloadData.iv.length
      cipher = crypto.createCipheriv(@cipherAlgo, @cipherKey, payloadData.iv)
    else
      cipher = crypto.createCipher(@cipherAlgo, @cipherKey)

    if @autoPadding?
      cipher.setAutoPadding(@autoPadding)

    digestData = []
    if authData?
      # allow inclusion of Additional Authenticated Data, which isn't encrypted but is authenticated;
      # this is often used for headers and other addressing info
      if Buffer.isBuffer(authData)
        payloadData.aad = authData
      else
        payloadData.aad = new Buffer(authData, @textEncoding)
      if @authentication == 'automatic'
        cipher.setAAD(payloadData.aad)
      else
        digestData.unshift(payloadData.aad)
    else
      payloadData.aad = new Buffer(0)

    # build ciphertext
    payloadData.data = Buffer.concat([cipher.update(plainData), cipher.final()])

    # build the auth string (if configured)
    if @authentication == 'automatic'
      payloadData.auth = cipher.getAuthTag()
    else if @authentication
      digestData.unshift(payloadData.iv)
      digestData.unshift(payloadData.cipherData)
      payloadData.auth = @digest(digestData)
    else
      payloadData.auth = new Buffer(0)

    # pack it up and go
    return @packPayload(payloadData, @payloadEncoding, @payloadDelimiter)


  decrypt: (payload, withAAD=false) ->

    if !@cipherKey?
      throw new Error('A cipher key is required')

    if typeof(payload) != 'string'
      payload = payload.toString()

    # unpack the parts of the payload
    {data, iv, auth, aad} = @unpackPayload(payload, @payloadEncoding, @payloadDelimiter)

    # detect whether there was an initVector used
    if iv?.length
      decipher = crypto.createDecipheriv(@cipherAlgo, @cipherKey, iv)
    else
      decipher = crypto.createDecipher(@cipherAlgo, @cipherKey)
      iv = new Buffer(0)

    # detect if any Additional Authenticated Data was included
    digestData = []
    if aad?.length
      if @authentication == 'automatic'
        decipher.setAAD(aad)
      else if @authentication
        digestData.unshift(aad)

    # do (or set up) authentication to make sure payload hasn't been tampered with
    if @authentication
      if !auth?.length
        auth = new Buffer(0)
      if @authentication == 'automatic'
        decipher.setAuthTag(auth)
      else
        digestData.unshift(iv)
        digestData.unshift(data)
        if !@cryptoSafeCompare(auth, @digest(digestData))
          throw new Error('Error authenticating encrypted data')

    if @autoPadding?
      decipher.setAutoPadding(@autoPadding)

    plainData = Buffer.concat([decipher.update(data), decipher.final()])
    if @textEncoding
      plainData = plainData.toString(@textEncoding)
    # the most common use case will be without any AAD included -- so to simplify that case, we just return the
    # plaintext string unless AAD is requested
    if withAAD
      return {data: plainData, aad: aad}
    else
      return plainData


  # compute manual auth tag
  digest: (dataBlobs) ->
    hmac = crypto.createHmac(@authentication, @authenticationKey)
    for data in dataBlobs
      hmac.update(data)
    return hmac.digest()


  # avoid timing attacks by refusing to shortcut out after the first non-matching byte
  cryptoSafeCompare: (val1, val2) ->
    if val1.length != val2.length
      return false

    difference = 0
    for byte,i in val1
      difference |= (byte ^ val2[i])

    return difference == 0


module.exports = Encryptor
