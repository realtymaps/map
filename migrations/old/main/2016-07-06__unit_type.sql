update config_data_normalization set
  input = input::jsonb || '{"unitType": "Property Unit Type"}'
where data_source_id='blackknight' and list='base' and output='address';
