module.exports = ->
  [
    {
      id: 1
      path: [
        {
          latitude: 45
          longitude: -74
        }
        {
          latitude: 30
          longitude: -89
        }
        {
          latitude: 37
          longitude: -122
        }
        {
          latitude: 60
          longitude: -95
        }
      ]
      stroke:
        color: "#6060FB"
        weight: 3

      editable: true
      draggable: true
      geodesic: true
      visible: true
      icons: [
        icon:
          path: google.maps.SymbolPath.BACKWARD_OPEN_ARROW

        offset: "25px"
        repeat: "50px"
      ]
    }
    {
      id: 2
      path: [
        {
          latitude: 47
          longitude: -74
        }
        {
          latitude: 32
          longitude: -89
        }
        {
          latitude: 39
          longitude: -122
        }
        {
          latitude: 62
          longitude: -95
        }
      ]
      stroke:
        color: "#6060FB"
        weight: 3

      editable: true
      draggable: true
      geodesic: true
      visible: true
      icons: [
        icon:
          path: google.maps.SymbolPath.BACKWARD_OPEN_ARROW

        offset: "25px"
        repeat: "50px"
      ]
    }
    {
      id: 3
      path: google.maps.geometry.encoding.decodePath("uowfHnzb}Uyll@i|i@syAcx}Cpj[_wXpd}AhhCxu[ria@_{AznyCnt^|re@nt~B?m|Awn`G?vk`RzyD}nr@uhjHuqGrf^ren@")
      stroke:
        color: "#4EAE47"
        weight: 3

      editable: false
      draggable: false
      geodesic: false
      visible: true
    }
  ]