-- fix cdn_photo binding mess up
-- https://github.com/realtymaps/map/pull/1113#discussion_r60743921
UPDATE listing
set
  cdn_photo='prodpull1.realtymapsterllc.netdna-cdn.com/api/photos/resize'
  || chr(63) || 'data_source_id='
  || data_source_id || '&data_source_uuid=' || data_source_uuid
where cdn_photo like '%cdn_photo=%';
