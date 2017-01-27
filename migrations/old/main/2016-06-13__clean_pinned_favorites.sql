drop table if exists temp_properties_selected;

create table temp_properties_selected (
  project_id int,
  rm_property_id text
);

insert into temp_properties_selected
  (select id, key
    from user_project, json_each(user_project.properties_selected)
    where user_project.properties_selected is not null
  );

-- wipe
update user_project
set properties_selected = '{}'::json
where properties_selected is not null;


create or replace function fix_properties_selected() RETURNS void AS $$
DECLARE
    r temp_properties_selected%rowtype;
BEGIN
    FOR r IN
      select * from temp_properties_selected
    LOOP
        update user_project set properties_selected = jsonb_set(
		user_project.properties_selected::jsonb, ('{' || r.rm_property_id || '}')::text[], ('{"rm_property_id":"' || r.rm_property_id  || '", "isPinned":true}')::jsonb)::json
	where user_project.id = r.project_id;
    END LOOP;
    RETURN;
END

$$ LANGUAGE plpgsql;

select fix_properties_selected();

drop function fix_properties_selected();

drop table temp_properties_selected;


--- ################################### FAVORTIES ###############################

drop table if exists temp_favorites;

create table temp_favorites (
  profile_id int,
  rm_property_id text
);

insert into temp_favorites
  (select id, key
    from user_profile, json_each(user_profile.favorites)
    where favorites is not null
  );

-- wipe
update user_profile
set favorites = '{}'::json
where favorites is not null;


create or replace function fix_favorites() RETURNS void AS $$
DECLARE
    r temp_favorites%rowtype;
BEGIN
    FOR r IN
      select * from temp_favorites
    LOOP
        update user_profile set favorites = jsonb_set(
		user_profile.favorites::jsonb, ('{' || r.rm_property_id || '}')::text[], ('{"rm_property_id":"' || r.rm_property_id  || '", "isFavorite":true}')::jsonb)::json
	where user_profile.id = r.profile_id;
    END LOOP;
    RETURN;
END

$$ LANGUAGE plpgsql;

select fix_favorites();

drop function fix_favorites();

drop table temp_favorites;
