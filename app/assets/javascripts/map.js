const create_map = function (position) {
  var baseMapLayer = new ol.layer.Tile({
  source: new ol.source.OSM()
 });
 var map = new ol.Map({
   target: 'map',
   layers: [ baseMapLayer],
   view: new ol.View({
   center: ol.proj.fromLonLat(position.longitude,  position.latitude), 
   zoom: 16 
   })
 });
 var marker = new ol.Feature({
   geometry: new ol.geom.Point(
    ol.proj.fromLonLat( position.longitude,  position.latitude )
   )
 });
 var vectorSource = new ol.source.Vector({
 features: [marker]
 });
 var markerVectorLayer = new ol.layer.Vector({
 source: vectorSource,
 });
 map.addLayer(markerVectorLayer);
}