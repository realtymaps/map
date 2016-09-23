ALTER TABLE retry_photos ADD COLUMN photo_id TEXT;


update retry_photos set photo_id='2323381' where data_source_uuid='211512161';
update retry_photos set photo_id='2359778' where data_source_uuid='212034069';
update retry_photos set photo_id='2360596' where data_source_uuid='212035161';
update retry_photos set photo_id='2364420' where data_source_uuid='212040026';
update retry_photos set photo_id='2368817' where data_source_uuid='213001944';
update retry_photos set photo_id='2370662' where data_source_uuid='213004228';
update retry_photos set photo_id='2374012' where data_source_uuid='213008398';
update retry_photos set photo_id='2374125' where data_source_uuid='213008540';
update retry_photos set photo_id='13150609' where data_source_uuid='213012525';
update retry_photos set photo_id='13150889' where data_source_uuid='213012960';
update retry_photos set photo_id='13151100' where data_source_uuid='213013302';
update retry_photos set photo_id='13151794' where data_source_uuid='213014440';
update retry_photos set photo_id='13152931' where data_source_uuid='213016321';
update retry_photos set photo_id='13861718' where data_source_uuid='213021233';
update retry_photos set photo_id='13938244' where data_source_uuid='213022239';
update retry_photos set photo_id='13942239' where data_source_uuid='213022400';
update retry_photos set photo_id='14007786' where data_source_uuid='213023596';
update retry_photos set photo_id='14015026' where data_source_uuid='213023940';
update retry_photos set photo_id='14607418' where data_source_uuid='213024027';
update retry_photos set photo_id='25860920' where data_source_uuid='214030831';
update retry_photos set photo_id='27380705' where data_source_uuid='214059344';
update retry_photos set photo_id='27679846' where data_source_uuid='214070416';
update retry_photos set photo_id='27693581' where data_source_uuid='214070948';
update retry_photos set photo_id='27812990' where data_source_uuid='215004338';
update retry_photos set photo_id='27842903' where data_source_uuid='215005464';
update retry_photos set photo_id='27932667' where data_source_uuid='215008695';
update retry_photos set photo_id='27937180' where data_source_uuid='215008907';
update retry_photos set photo_id='27939893' where data_source_uuid='215009012';
update retry_photos set photo_id='27944067' where data_source_uuid='215009180';
update retry_photos set photo_id='28633579' where data_source_uuid='215034161';
update retry_photos set photo_id='28987105' where data_source_uuid='215047711';
update retry_photos set photo_id='29083484' where data_source_uuid='215051091';
update retry_photos set photo_id='29083851' where data_source_uuid='215051101';
update retry_photos set photo_id='29084038' where data_source_uuid='215051109';
update retry_photos set photo_id='29581203' where data_source_uuid='215070302';


ALTER TABLE retry_photos ALTER COLUMN photo_id SET NOT NULL;
