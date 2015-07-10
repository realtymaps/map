insert into django_content_type
   ( model, name, app_label)
values ( 'mls_config', 'mls config', 'management');


insert into auth_permission ( "name", "content_type_id", "codename")(
    SELECT 'Can add mls config', id, 'add_mlsconfig' from django_content_type
    WHERE name = 'mls config'
    limit 1
);

insert into auth_permission ( "name", "content_type_id", "codename")(
    SELECT 'Can change mls config', id, 'change_mlsconfig' from django_content_type
    WHERE name = 'mls config'
    limit 1
);

insert into auth_permission ( "name", "content_type_id", "codename")(
    SELECT 'Can change mls config main property data ', id, 'change_mlsconfig_mainpropertydata' from django_content_type
    WHERE name = 'mls config'
    limit 1
);

insert into auth_permission ( "name", "content_type_id", "codename")(
    SELECT 'Can delete mls config', id, 'delete_mlsconfig' from django_content_type
    WHERE name = 'mls config'
    limit 1
);
