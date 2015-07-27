insert into django_content_type
   ( model, name, app_label)
values ( 'company', 'user company', 'company management');


insert into auth_permission ( "name", "content_type_id", "codename")(
    SELECT 'Can add user company', id, 'add_company' from django_content_type
    WHERE name = 'user company'
    limit 1
);

insert into auth_permission ( "name", "content_type_id", "codename")(
    SELECT 'Can change user company', id, 'change_company' from django_content_type
    WHERE name = 'user company'
    limit 1
);

insert into auth_permission ( "name", "content_type_id", "codename")(
    SELECT 'Can delete user company', id, 'delete_company' from django_content_type
    WHERE name = 'user company'
    limit 1
);
