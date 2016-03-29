update config_mls set
listing_data=jsonb_set(listing_data, '{photoRes}', '{"width":"1024", "height":"768"}', true)
where id='swflmls';

update config_mls set
listing_data=jsonb_set(listing_data, '{photoRes}', '{"width":"300", "height":"225"}', true)
where id='MRED';

update config_mls set
listing_data=jsonb_set(listing_data, '{photoRes}', '{"width":"800", "height":"600"}', true)
where id='GLVAR';
