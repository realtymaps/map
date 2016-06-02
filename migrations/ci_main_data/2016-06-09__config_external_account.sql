insert into config_external_accounts (name, other, api_key)
select 'vero', '{
"auth_token":"crap1$",
"secret_api_key":"crap2$",
"public_api_key":"crap3$"
}', 'crap4$'
where not exists (select name from config_external_accounts where name = 'vero');
