DROP TABLE IF EXISTS mv_property_details;
ALTER TABLE user_notes rename column geom_point_raw to geometry_center_raw;
ALTER TABLE user_notes rename column geom_point_json to geometry_center;
ALTER TABLE data_parcel rename column geom_point_raw to geometry_center_raw;
ALTER TABLE data_parcel rename column geom_point_json to geometry_center;
ALTER TABLE data_parcel rename column geom_polys_raw to geometry_raw;
ALTER TABLE data_parcel rename column geom_polys_json to geometry;
