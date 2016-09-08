insert into user_project ( name,           archived, pins, sandbox, status,
  auth_user_id)
  values                 ( 'Dans Project', 'f','{}', 'f',     'active',
  (select id from auth_user where first_name = 'CIRCLE' and last_name = 'CI'));


insert into user_profile (
  filters,
  map_toggles,
  map_position,
  map_results,
  auth_user_id,
  project_id,
  account_image_id, favorites, can_edit)
  values (
    '{"hasImages":false,"soldRange":"120 day","discontinued":false,"status":["for sale","pending"]}',
    '{"showResults":false,"showDetails":false,"showFilters":false,"showSearch":false,"isFetchingLocation":false,"hasPreviousLocation":false,"showAddresses":false,"showPrices":true,"showNotes":false,"showMail":false,"propertiesInShapes":false,"isSketchMode":false,"isAreaDraw":false,"showOldToolbar":false,"showAreaTap":false,"showNoteTap":false}',
    '{"center":{"lng":-81.81898355484009,"lat":26.1915649539659,"lon":-81.81898355484009,"latitude":26.1915649539659,"longitude":-81.81898355484009,"zoom":15}}',
    '{}',
    (select id from auth_user where first_name = 'CIRCLE' and last_name = 'CI'),
    (select id from user_project where name = 'Dans Project'),
    null, '{}', 't'
  );
