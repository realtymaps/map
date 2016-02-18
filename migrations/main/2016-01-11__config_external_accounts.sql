--http://stackoverflow.com/questions/4069718/postgres-insert-if-does-not-exist-already

BEGIN;
LOCK TABLE config_external_accounts IN SHARE ROW EXCLUSIVE MODE;

-- NOTE that api_key is public live api_keys for BOTH!!!
insert into config_external_accounts (name, other, api_key)
select 'stripe', '{
"secret_test_api_key":"JveZztx7CWYkuAm8YSxPGw==$$o5iBHmYvdXAGgTF7f2Ct+1Zr0BRiDQNvThBpSr4zZlg=$",
"public_test_api_key":"l6SM3NkvA6hp16NQUxijjg==$$I7VWDm+fXQpHWdO3e96SrjJuBdbPIkDBepdaBBkMdr4=$",
"secret_live_api_key":"EKQGSSL5aBkxhEDCW5OEZQ==$$3zPES7Punnfw2kDn4yQlGxpPTwq+65pDCyJPETlyu+M=$",
"public_live_api_key":"X/6PfpmAS0kh0DAj1381FQ==$$JbB3YGOVivhg22PMH4QuK5q0OmYkfZiRkSwGadZefJw=$"
}', 'X/6PfpmAS0kh0DAj1381FQ==$$JbB3YGOVivhg22PMH4QuK5q0OmYkfZiRkSwGadZefJw=$'
where not exists (select name from config_external_accounts where name = 'stripe');


insert into config_external_accounts (name, other, api_key)
select 'vero', '{
"auth_token":"OaWKwG/XNTzyYCDPZwcmHA==$$SxpYz/+RpMz2ObpDHB18CLfzXZM79jzSb9DyNFes+92w8+D1pVWWWVNYhBooao4DXhIcttep0H6ysXbQR3gKnMsBtVk/bgiD1bn7qiV1nXqD10rFdp0DLT5ZtoNLHRZLLq1RwIngWDPfFZfw$",
"secret_api_key":"jt5u40K9326FfZIJFiPo3A==$$9MIwlOyDGSfB2a5HYbj/4bTQe2gGnPhyYAKTvNRGVZ/buevOlpit8Q==$",
"public_api_key":"lUSFcvs5GFDJ/6Fn+ggQdg==$$mzYyejNm2lS2kCb7oUZIGEPWNT0eyLXjI9ZRUW28bcFAacH/ywsbbg==$"
}', 'lUSFcvs5GFDJ/6Fn+ggQdg==$$mzYyejNm2lS2kCb7oUZIGEPWNT0eyLXjI9ZRUW28bcFAacH/ywsbbg==$'
where not exists (select name from config_external_accounts where name = 'vero');
COMMIT;
