ALTER TABLE config_mls ALTER COLUMN listing_data TYPE jsonb;

update config_mls set
listing_data=jsonb_set(listing_data, '{largestPhotoObject}', '"XLargePhoto"', true)
where id='swflmls';
