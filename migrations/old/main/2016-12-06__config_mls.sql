update config_mls
  set listing_data=jsonb_set(listing_data,'{photoObjects}', '["Photo", "ThNail","HrPhoto"]')
where id = 'MRED';

update config_mls
  set listing_data=jsonb_set(listing_data, '{photoInfo}', '"http://www.mredllc.com/rets/documents/RETS%20Developer%20Start%20Guide1.pdf"')
where id = 'MRED';


update config_mls
  set listing_data=jsonb_set(listing_data,'{photoObjects}', '["HiRes", "640x480", "Thumbnail", "Photo"]')
where id = 'RAPB';

update config_mls
  set listing_data=jsonb_set(listing_data, '{photoInfo}', '"https://www.flexmls.com/developers/rets/tutorials/best-practices-photo-downloads/"')
where id = 'RAPB';

update config_mls
  set listing_data=jsonb_set(listing_data, '{photoRes}', '{"width":300,"height":225}')
where id = 'RAPB';
