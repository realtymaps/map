update config_mls
  set listing_data=jsonb_set(listing_data, '{lastModTime}',
	jsonb_build_object('name',listing_data->'field', 'type',listing_data->'field_type'))
where listing_data->'field_type' is not null;

update config_mls
  set listing_data=jsonb_set(listing_data, '{lastModTime}',
	jsonb_build_object('name',listing_data->'field'))
where listing_data->'field_type' is null;


update config_mls
  set agent_data=jsonb_set(agent_data, '{lastModTime}',
	jsonb_build_object('name',agent_data->'field', 'type',agent_data->'field_type'))
where agent_data->'field_type' is not null;

update config_mls
  set agent_data=jsonb_set(agent_data, '{lastModTime}',
	jsonb_build_object('name',agent_data->'field'))
where agent_data->'field_type' is null;
