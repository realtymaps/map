DELETE FROM config_data_normalization
WHERE list = 'base' AND data_type = 'mortgage' AND output IN ('owner_name', 'owner_name_2', 'owner_address');
