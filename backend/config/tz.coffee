tz = require 'timezone-js'
path = require 'path'

###
# currently, we only load time zone data for America/New_York (eastern time).  To get more, execute these commands to
# create a new customTzData.json file (customizing the city list):
#
# mkdir /tmp/tz
# curl ftp://ftp.iana.org/tz/tzdata-latest.tar.gz -o /tmp/tz/tzdata-latest.tar.gz
# tar -xvzf /tmp/tz/tzdata-latest.tar.gz -C /tmp/tz
# node ./node_modules/timezone-js/src/node-preparse.js /tmp/tz "America/New_York, America/Next_City, Asia/Another_City" > ./backend/config/tz/customTzData.json
#
# If we ever want to load more than just specific cities (i.e. all of a continent or all of the world), see the
# documentation at https://github.com/mde/timezone-js
###

tz.timezone.loadingScheme = tz.timezone.loadingSchemes.MANUAL_LOAD
tz.timezone.loadZoneJSONData(path.join(__dirname, './tz/customTzData.json'), true)

module.exports = tz
