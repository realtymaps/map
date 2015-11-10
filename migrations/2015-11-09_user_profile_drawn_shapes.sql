-- conditionally add draw_shapes col to user_profile
SELECT f_add_col('user_profile', 'drawn_shapes', 'json');
