alter table user_project add column properties_selected json;

update user_project set properties_selected = user_profile.properties_selected
from user_profile
where user_profile.project_id = user_project.id;

alter table user_profile rename properties_selected to favorites;
