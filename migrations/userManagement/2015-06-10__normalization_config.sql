SELECT easy_normalization_insert ('swflmls', 'base', 'close_date', FALSE, '"Close Date"', $$
  validators.datetime()
$$);
