validation =
  url: /((([A-Za-z]{3,9}:(?:\/\/)?)(?:[-;:&=\+\$,\w]+@)?[A-Za-z0-9.-]+|(?:www.|[-;:&=\+\$,\w]+@)[A-Za-z0-9.-]+)((?:\/[\+~%\/.\w-_]*)?\??(?:[-\+=&;%@.\w_]*)#?(?:[\w]*))?)/
  email: /^([\w-\.]+)@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.)|(([\w-]+\.)+))([a-zA-Z]{2,4}|[0-9]{1,3})(\]?)$/
  number: /^\d+$/
  #http://stackoverflow.com/questions/16699007/regular-expression-to-match-standard-10-digit-phone-number
  phoneNonNumeric: /[-. (]*/g
  phone:
    ///^\s*             #Line start, match any whitespaces at the beginning if any.
    (?:\+?(\d{1,3}))?   #GROUP 1: The country code. Optional.
    [-. (]*             #Allow certain non numeric characters that may appear between the Country Code and the Area Code.
    (\d{3})             #GROUP 2: The Area Code. Required.
    [-. )]*             #Allow certain non numeric characters that may appear between the Area Code and the Exchange number.
    (\d{3})             #GROUP 3: The Exchange number. Required.
    [-. ]*              #Allow certain non numeric characters that may appear between the Exchange number and the Subscriber number.
    (\d{4})             #Group 4: The Subscriber Number. Required.
    (?:\#|x\.?
    |ext\.?|extension)? #Group 5: The Extension number. Optional.
    \s*$///
  address: /\d{1,20}((\b\w*\b\s){1,2}\w*(\.)?(\s)?){1,4}/
  #  http://stackoverflow.com/questions/578406/what-is-the-ultimate-postal-code-and-zip-regex
  zipcode:
    US: /^\d{5}([\-]?\d{4})?$/
    UK: /^(GIR|[A-Z]\d[A-Z\d]??|[A-Z]{2}\d[A-Z\d]??)[ ]??(\d[A-Z]{2})$/
    DE: /\b((?:0[1-46-9]\d{3})|(?:[1-357-9]\d{4})|(?:[4][0-24-9]\d{3})|(?:[6][013-9]\d{3}))\b/
    CA: /^([ABCEGHJKLMNPRSTVXY]\d[ABCEGHJKLMNPRSTVWXYZ])\ {0,1}(\d[ABCEGHJKLMNPRSTVWXYZ]\d)$/
    FR: /^(F-)?((2[A|B])|[0-9]{2})[0-9]{3}$/
    IT: /^(V-|I-)?[0-9]{5}$/
    AU: /^(0[289][0-9]{2})|([1345689][0-9]{3})|(2[0-8][0-9]{2})|(290[0-9])|(291[0-4])|(7[0-4][0-9]{2})|(7[8-9][0-9]{2})$/
    NL: /^[1-9][0-9]{3}\s?([a-zA-Z]{2})?$/
    ES: /^([1-9]{2}|[0-9][1-9]|[1-9][0-9])[0-9]{3}$/
    DK: /^([D-d][K-k])?( |-)?[1-9]{1}[0-9]{3}$/
    SE: /^(s-|S-){0,1}[0-9]{3}\s?[0-9]{2}$/
    BE: /^[1-9]{1}[0-9]{3}$/
    IN: /^\d{6}$/

  password: ///
    ^.*(?!.*?(.)\1{2,})     #doesn't repeat a char more than twice
    (?=.{8,})               #min 8 chars
    (?=.*[$@$!%*#?&])       #one special char
    (?=.*\d)                #one number
    (?=.*[a-z])             #one lowercase
    (?=.*[A-Z]).*$///       #one uppercase

commonConfig =
  SUPPORT_EMAIL: 'support@realtymaps.com'
  UNEXPECTED_MESSAGE: (troubleshooting) ->
    return "Oops! Something unexpected happened! Please try again in a few minutes. If the problem continues,
            please let us know by emailing #{commonConfig.SUPPORT_EMAIL}, and giving us the following error
            message: "+(if troubleshooting then "<br/><code>#{troubleshooting}</code>" else '')

  modals:
    animationsEnabled: true

  map:
    options:
      zoomThresh:
        addressParcel: 18
        price: 15 # markercluster option `disableClusteringAtZoom` depends on this value
        ordering: 12
        roundDigit: 10 # threshold for when to round first decimal
        maxGrid: 6 # zoom level when grid will be largest (nearest integer lat/lng)

  backendClustering:
    resultThreshold: 2000

  images:
    dimensions:
      profile:
        width: 200
        height: 200
        quality: .8

  mlsicons:
    filelist: ['01.png', '02.jpg', '03.jpg', '04.jpg', '05.png', '06.gif', '07.gif']

  pdfUpload:
    # sufficiently large random string via powers, http://stackoverflow.com/questions/10726909/random-alpha-numeric-string-in-javascript
    # note: consider the expoment of first `pow` is L + 1, and the exponent of the second `pow` is L, your random string will have length L
    getKey: () -> "#{Math.round((Math.pow(36, 17) - Math.random() * Math.pow(36, 16))).toString(36).slice(1)}.pdf"

  validation: validation
  regexes: validation
module.exports = commonConfig
