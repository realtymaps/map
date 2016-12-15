update config_mls
  set listing_data=jsonb_set(listing_data, '{Location}', '1')
where id = 'RAPB';
