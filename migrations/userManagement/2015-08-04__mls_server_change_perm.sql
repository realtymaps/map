insert into auth_permission ( "name", "content_type_id", "codename")(
    SELECT 'Can change mls config server info', id, 'change_mlsconfig_serverdata' from django_content_type
    WHERE name = 'mls config'
    limit 1
);
