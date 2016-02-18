CREATE TABLE listing (
    rm_inserted_time timestamp without time zone DEFAULT now_utc() NOT NULL,
    rm_modified_time timestamp without time zone DEFAULT now_utc() NOT NULL,
    data_source_id text NOT NULL,
    batch_id text NOT NULL,
    deleted text,
    up_to_date timestamp without time zone NOT NULL,
    change_history json DEFAULT '[]'::json NOT NULL,
    rm_property_id text NOT NULL,
    fips_code integer NOT NULL,
    parcel_id text NOT NULL,
    address json,
    price numeric NOT NULL,
    days_on_market integer NOT NULL,
    bedrooms integer,
    baths_full integer,
    acres numeric,
    sqft_finished integer,
    status text NOT NULL,
    substatus text NOT NULL,
    status_display text NOT NULL,
    shared_groups json NOT NULL,
    subscriber_groups json NOT NULL,
    hidden_fields json NOT NULL,
    ungrouped_fields json,
    data_source_uuid text NOT NULL,
    close_date timestamp without time zone,
    hide_listing boolean NOT NULL,
    discontinued_date timestamp without time zone,
    hide_address boolean NOT NULL,
    rm_raw_id integer NOT NULL,
    inserted text DEFAULT 'invalid'::text NOT NULL,
    updated text
);

CREATE UNIQUE INDEX listing_data_source_id_data_source_uuid_idx ON listing USING btree (data_source_id, data_source_uuid);
CREATE INDEX listing_rm_property_id_deleted_hide_listing_close_date_idx ON listing USING btree (rm_property_id, deleted, hide_listing, close_date DESC);
CREATE INDEX listing_batch_id_idx ON listing USING btree (batch_id);
CREATE TRIGGER update_modified_time_listing BEFORE UPDATE ON listing FOR EACH ROW EXECUTE PROCEDURE update_rm_modified_time_column();
