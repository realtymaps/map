insert into django_content_type
   ( model, name, app_label)
values ( 'useraccount', 'user account project', 'management');


insert into auth_permission ( "name", "content_type_id", "codename")(
    SELECT 'Can add user project', id, 'add_project' from django_content_type
    WHERE name = 'user account project'
    limit 1
);

insert into auth_permission ( "name", "content_type_id", "codename")(
    SELECT 'Can change user project', id, 'change_project' from django_content_type
    WHERE name = 'user account project'
    limit 1
);

insert into auth_permission ( "name", "content_type_id", "codename")(
    SELECT 'Can delete user project', id, 'delete_project' from django_content_type
    WHERE name = 'user account project'
    limit 1
);
