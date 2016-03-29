update config_mls set
listing_data=jsonb_set(listing_data, '{largestPhotoObject}', '"HrPhoto"', true)
where id='MRED';

update config_mls set
listing_data=jsonb_set(listing_data, '{photoRes}', '{"width":"600", "height":"480"}', true)
where id='MRED';
