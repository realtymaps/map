ALTER TABLE user_state ADD PRIMARY KEY ("id");

insert into auth_user
( "is_superuser", "cell_phone", "is_active", "last_login", "work_phone", "password", "date_joined", "first_name", "username", "last_name", "email", "is_staff")
values
( 'f', null, 't', '2014-12-18 14:55:04-05', null, 'bcrypt$$2a$13$ez2MItI1xAn0xMPeeHl44evhTsCo2lVDmpeoE.t/fpKaRzj2egIQe', '2014-08-19 07:54:49-04', '', 'load_test', '', '', 'f');


insert into auth_user_user_permissions ( "user_id", "permission_id")(
    SELECT id, '19' from auth_user
    WHERE username = 'load_test'
    limit 1
);
