CREATE TABLE parcel_deletes (
  rm_inserted_time timestamp(6) NOT NULL DEFAULT now_utc(),
	rm_property_id text NOT NULL,
	data_source_id text NOT NULL,
	batch_id text NOT NULL
)
WITH (OIDS=FALSE);

CREATE INDEX parcel_deletes_idx1 ON parcel_deletes USING btree(data_source_id, batch_id, rm_property_id);
