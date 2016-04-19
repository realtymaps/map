alter table parcel add column rm_raw_id int4 NOT NULL DEFAULT -1;

alter table parcel alter column rm_raw_id DROP DEFAULT;
