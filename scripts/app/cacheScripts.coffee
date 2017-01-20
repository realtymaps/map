# This script uploads app scripts (map.bundle.js) and sourcemap (map.bundle.js.map)
# to S3 after a successful prod deploy. The files are world-readable but the location
# is secret (SCRIPTS_CACHE_SECRET_KEY). This makes it possible to sourcemap stacktraces
# captured from a particular git revision at a later point in time.

aws = require('../../backend/services/service.aws')
fs = require('fs')
Promise = require('bluebird')
exec = Promise.promisify(require('child_process').exec)

S3_BUCKET = process.env.S3_BUCKET ? 'rmaps-dropbox'

if process.env.NODE_ENV != "production" && !process.env.FORCE_CACHE_SCRIPTS
  console.log "Environment is #{process.env.NODE_ENV}, skipping script upload"
  process.exit(0)

if !process.env.SCRIPTS_CACHE_SECRET_KEY
  console.error "ERROR: SCRIPTS_CACHE_SECRET_KEY missing"
  process.exit(1)

if !S3_BUCKET
  console.error "ERROR: S3_BUCKET missing"
  process.exit(1)

console.log("Checking git rev...")
Promise.try () ->
  if process.env.IS_HEROKU == '1'
    return process.env.HEROKU_SLUG_COMMIT
  else
    return exec 'git rev-parse HEAD'
.then ([rev]) ->
  if !rev
    console.error "No git revision!"
    return

  rev = rev.trim()

  console.log("Uploading scripts and sourcemap (rev #{rev}) to S3")
  Promise.props
    scripts: aws.putObject(
      extAcctName: S3_BUCKET
      Key: "#{process.env.SCRIPTS_CACHE_SECRET_KEY}/#{rev}/map.bundle.js"
      Body: fs.createReadStream("#{__dirname}/../../_public/scripts/map.bundle.js")
    )
    sourcemap: aws.putObject(
      extAcctName: S3_BUCKET
      Key: "#{process.env.SCRIPTS_CACHE_SECRET_KEY}/#{rev}/map.bundle.js.map"
      Body: fs.createReadStream("#{__dirname}/../../_public/scripts/map.bundle.js.map")
    )
  .then (result) ->
    console.log("Upload script+sourcemap successful")
.then () ->
  Promise.promisify(fs.rename)("#{__dirname}/../../_public/scripts/map.bundle.js.map","/tmp/map.bundle.js.map")
.then () ->
  console.log("Moved soucemap to /tmp")
  process.exit(0)
.catch (err) ->
  console.error err
  process.exit(1)
