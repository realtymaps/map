DROP TRIGGER update_modified_geom_jsons_parcel ON parcel;
DROP TRIGGER insert_modified_geom_jsons_parcel ON parcel;
DROP TRIGGER update_geom_point_raw_from_geom_polys_raw_parcel ON parcel;
DROP TRIGGER insert_geom_point_raw_from_geom_polys_raw_parcel ON parcel;

DROP FUNCTION update_geom_point_raw_from_geom_polys_raw();


ALTER TABLE parcel RENAME COLUMN geom_point_raw TO geometry_center_raw;
ALTER TABLE parcel RENAME COLUMN geom_polys_raw TO geometry_raw;

ALTER TABLE parcel RENAME COLUMN geom_point_json TO geometry_center;
ALTER TABLE parcel RENAME COLUMN geom_polys_json TO geometry;
