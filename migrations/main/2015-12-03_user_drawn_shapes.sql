-- delete mispelled
SELECT f_drop_col('user_drawn_shapes', 'neighborhood_name');
SELECT f_drop_col('user_drawn_shapes', 'neighborhood_details');

SELECT f_add_col('user_drawn_shapes', 'neighbourhood_name', 'varchar(50)');
SELECT f_add_col('user_drawn_shapes', 'neighbourhood_details', 'varchar(50)');
