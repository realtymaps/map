CREATE TABLE external_accounts (
	"id" SERIAL NOT NULL,
	"name" varchar,
	"username" varchar,
	"password" varchar,
	"api_key" varchar,
	"other" json,
	PRIMARY KEY ("id")
)
WITH (OIDS=FALSE);


insert into external_accounts (name, username, password, api_key)
  values(
    'heroku',
    'EoHpzvOWJ6qKNons8MOGpA==$$JrdeoH05swF2V3fC3ozijyCqC0V/8tA=$',
    '5cv/YvJvbqXS2ALm9a22cQ==$$8XZQOyXt0hVKN+SVY12KdOXpoQ==$',
		'lA2TJjR0U8ir4NxKakY5Xg==$$y5dpIbHSmCUWek6wFuwhwCl3VlyhiLII9cYfUF9pT5S8cNg7$'
  );

insert into external_accounts ( name, username, password, other)
  values(
    'digimaps',
    'hobLzuQ85bYSCucHL2yg2A==$$7LG66Dux+NTn4fGfaA==$',
    'iMs5I3ydqfrML4khGBG+jg==$$R1ufjS2P5w==$',
    '{"URL": "yEgpG8UlNfPEPV2t5Bmi4w==$$V5eVtnpcu0YZfr5impU=$"}'::json
  );
