INSERT INTO auth_user (password, last_login, is_superuser, username, first_name, last_name, email, is_staff, is_active, date_joined)
SELECT 'bcrypt$$2a$13$gJGF.aPvmNpx4IuedA455upZVH70/aHArwWRx3vecielkikzPo232', '2015-05-26 11:20:58.243975-04', true, 'jesse', '', '', '', true, true, '2015-05-26 11:20:23-04'
WHERE NOT EXISTS (SELECT * FROM auth_user WHERE username='jesse');
