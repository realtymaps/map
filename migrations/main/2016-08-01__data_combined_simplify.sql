-- .000002
-- number is from experimenting with the below commented queries
-- they allow you to see what your potentially losing when simplifying the shapes

-- SELECT avg(ST_NPoints(st_simplify(geometry_raw, .000002))) from data_combined;
-- SELECT sum(ST_NPoints(geometry_raw)) from data_combined;
update data_combined
  set geometry_raw = st_simplify(geometry_raw, .000002)
where active = true;


alter table data_combined add column geometry_center_raw geometry;


-- create ultimate simple representation (one point) for spatial queries
update data_combined
  set geometry_center_raw = st_centroid(geometry_raw)
where active = true;
