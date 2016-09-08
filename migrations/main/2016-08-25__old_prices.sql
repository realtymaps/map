update user_mail_campaigns set price_per_letter = 1.05 where price_per_letter is null and status != 'ready';
