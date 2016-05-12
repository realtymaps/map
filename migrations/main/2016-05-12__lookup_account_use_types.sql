update lookup_account_use_types
  set
    description= 'I''m a staff member.'
where description like '%memeber%' and type = 'staff';
