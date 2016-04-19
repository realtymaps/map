app = require '../../app.coffee'
module.exports = app

app.controller 'rmapsSmallDetailsCtrl', ($scope, $log, rmapsResultsFormatterService, rmapsPropertyFormatterService) ->
  $log = $log.spawn 'rmapsSmallDetailsCtrl'
  $log.debug "rm_property_id: #{JSON.stringify $scope.model.rm_property_id}"

  $scope.formatters =
    results: new rmapsResultsFormatterService scope: $scope
    property: new rmapsPropertyFormatterService

  $scope.property = _.cloneDeep $scope.model

  # Property service will return a photos object with this structure. First photo may be a duplicate
  $scope.property.photos = _.values
    '1':
      'key': 'CqF5p-hkth84_BreQVF19ZpP0LoYHGAmHehp71ufcqQ7VOw4BKDpiWOcFJODkq9J/swflmls/30288923_1.jpeg'
      'url': 'https://s3.amazonaws.com/rmaps-listing-photos/CqF5p-hkth84_BreQVF19ZpP0LoYHGAmHehp71ufcqQ7VOw4BKDpiWOcFJODkq9J/swflmls/30288923_1.jpeg'
      'objectData':
        'originalFilename': 'patio.jpg'
    '2':
      'key': 'i4B3Y6p1o4TOXfK4eXYlapRHoyqNMppgfY6kHjmteMMbQFfZBTbqsKaMsAw2IHu6/swflmls/30288923_2.jpeg'
      'url': 'https://s3.amazonaws.com/rmaps-listing-photos/i4B3Y6p1o4TOXfK4eXYlapRHoyqNMppgfY6kHjmteMMbQFfZBTbqsKaMsAw2IHu6/swflmls/30288923_2.jpeg'
      'objectData':
        'originalFilename': 'living area.jpg'
    '3':
      'key': 'dO_1SpdqBw9xYckyP3oUxso5IE2hWHJmDUVP_TsuPLDFKCSDmBhKgY61DlRYWr1W/swflmls/30288923_3.jpeg'
      'url': 'https://s3.amazonaws.com/rmaps-listing-photos/dO_1SpdqBw9xYckyP3oUxso5IE2hWHJmDUVP_TsuPLDFKCSDmBhKgY61DlRYWr1W/swflmls/30288923_3.jpeg'
      'objectData':
        'originalFilename': 'living area2.jpg'
    '4':
      'key': 'lGCdMhDxze1PwX88vZLjUqgT51N6zzHyrHSMd43XrGiJHka0G-z3PPCBOXDPnA5S/swflmls/30288923_4.jpeg'
      'url': 'https://s3.amazonaws.com/rmaps-listing-photos/lGCdMhDxze1PwX88vZLjUqgT51N6zzHyrHSMd43XrGiJHka0G-z3PPCBOXDPnA5S/swflmls/30288923_4.jpeg'
      'objectData':
        'originalFilename': 'kitchen.jpg'
    '5':
      'key': 'QgDyksjpZp8V1JW8XRSPiiu4dZXVhE_X5AUlQoC_uyIklSPYlh9FOKMD6GMLcyId/swflmls/30288923_5.jpeg'
      'url': 'https://s3.amazonaws.com/rmaps-listing-photos/QgDyksjpZp8V1JW8XRSPiiu4dZXVhE_X5AUlQoC_uyIklSPYlh9FOKMD6GMLcyId/swflmls/30288923_5.jpeg'
      'objectData':
        'originalFilename': 'dining.jpg'
    '6':
      'key': 'oPiE9A3gBJf0wkfUw8CrI6Dbh1lOLj6aHIuRyAjQqigu6wgAKoUCMjujyMfmYOdk/swflmls/30288923_6.jpeg'
      'url': 'https://s3.amazonaws.com/rmaps-listing-photos/oPiE9A3gBJf0wkfUw8CrI6Dbh1lOLj6aHIuRyAjQqigu6wgAKoUCMjujyMfmYOdk/swflmls/30288923_6.jpeg'
      'objectData':
        'originalFilename': 'study.jpg'
    '7':
      'key': 'mlppTMRJk-IcihZLGvIEg8uZNbgqYY1WTTx83T01XTSOVwg9trdOMZ1c_F0AHWW7/swflmls/30288923_7.jpeg'
      'url': 'https://s3.amazonaws.com/rmaps-listing-photos/mlppTMRJk-IcihZLGvIEg8uZNbgqYY1WTTx83T01XTSOVwg9trdOMZ1c_F0AHWW7/swflmls/30288923_7.jpeg'
      'objectData':
        'originalFilename': 'master br.jpg'
    '8':
      'key': 'zrtXNwZB6cWH7C8hcO5yCbTLiEowPST6_Rht__kNbYiI3GXQDvaaMo7TBEuHXCHo/swflmls/30288923_8.jpeg'
      'url': 'https://s3.amazonaws.com/rmaps-listing-photos/zrtXNwZB6cWH7C8hcO5yCbTLiEowPST6_Rht__kNbYiI3GXQDvaaMo7TBEuHXCHo/swflmls/30288923_8.jpeg'
      'objectData':
        'originalFilename': 'bath.jpg'
    '9':
      'key': 'QKWoGotiCDdb8CYvToq9CBZQPN7PC_PsEpIr0OW_N_WzPp8R2U7TU4bkzl1zwkH3/swflmls/30288923_9.jpeg'
      'url': 'https://s3.amazonaws.com/rmaps-listing-photos/QKWoGotiCDdb8CYvToq9CBZQPN7PC_PsEpIr0OW_N_WzPp8R2U7TU4bkzl1zwkH3/swflmls/30288923_9.jpeg'
      'objectData':
        'originalFilename': 'br 2.jpg'
    '10':
      'key': 'b15GvMJdWPrUMk7t5vrCBqluHtMolZnsR2Tk5zD7P2QpLrl9WYZZJZL_M9-GPRVC/swflmls/30288923_10.jpeg'
      'url': 'https://s3.amazonaws.com/rmaps-listing-photos/b15GvMJdWPrUMk7t5vrCBqluHtMolZnsR2Tk5zD7P2QpLrl9WYZZJZL_M9-GPRVC/swflmls/30288923_10.jpeg'
      'objectData':
        'originalFilename': 'bath.jpg'
    '11':
      'key': 'MxkYok-xjV7vA17cWm6kHm4JQI6MfsBcoTjwLE6ulGFIJYDwZogYqk2B2BpfHwoa/swflmls/30288923_11.jpeg'
      'url': 'https://s3.amazonaws.com/rmaps-listing-photos/MxkYok-xjV7vA17cWm6kHm4JQI6MfsBcoTjwLE6ulGFIJYDwZogYqk2B2BpfHwoa/swflmls/30288923_11.jpeg'
      'objectData':
        'originalFilename': 'garage.jpg'
    '12':
      'key': 'OzYSee-LHjni0H_A7XGnKimxEGjlBUjEA80PU2Z6DCKrf7H4ZpTbEdfZWsazr0de/swflmls/30288923_12.jpeg'
      'url': 'https://s3.amazonaws.com/rmaps-listing-photos/OzYSee-LHjni0H_A7XGnKimxEGjlBUjEA80PU2Z6DCKrf7H4ZpTbEdfZWsazr0de/swflmls/30288923_12.jpeg'
      'objectData':
        'originalFilename': 'poolside.jpg'

  $log.debug $scope.property.photos
  for photo in $scope.property.photos
    # Show captions like 'bedroom1', 'kitchen', etc from filenames
    photo.caption = photo.objectData?.originalFilename?.replace /\.\w+/, ''
