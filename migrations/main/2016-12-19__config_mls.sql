-- map field and field_type to lastModTime:{name, type}
update config_mls
  set listing_data=jsonb_set(listing_data, '{lastModTime}',
	jsonb_build_object('name',listing_data->'field', 'type',listing_data->'field_type'))
where listing_data->'field_type' is not null and listing_data->'field' is not null;

update config_mls
  set listing_data=jsonb_set(listing_data, '{lastModTime}',
	jsonb_build_object('name',listing_data->'field'))
where listing_data->'field_type' is null and listing_data->'field' is not null;

update config_mls
  set agent_data=jsonb_set(agent_data, '{lastModTime}',
	jsonb_build_object('name',agent_data->'field', 'type',agent_data->'field_type'))
where agent_data->'field_type' is not null and agent_data->'field' is not null;

update config_mls
  set agent_data=jsonb_set(agent_data, '{lastModTime}',
	jsonb_build_object('name',agent_data->'field'))
where agent_data->'field_type' is null and agent_data->'field' is not null;

-- remove field and field_type
update config_mls
  set
  listing_data=listing_data - 'field',
  agent_data=agent_data - 'field';

  update config_mls
    set
    listing_data=listing_data - 'field_type',
    agent_data=agent_data - 'field_type';
