DROP TABLE IF EXISTS view_definitions;
CREATE TABLE view_definitions (
  "view_id" TEXT NOT NULL, -- the identifier of the dynamic view this clause is part of 
  "clause_type" TEXT NOT NULL, -- the type of clause this row represents; one of: SELECT, FROM, WHERE, ORDER BY, INDEX
  "definition" TEXT NOT NULL, -- the text that actually defines the clause
  "name" TEXT, -- the name of the column, table, index, etc as appropriate for the clause
  "aux" TEXT, -- auxiliary info needed.  Right now, this is used only for FROM to specify a join condition, and INDEX to specify the type.  It could be used for other things later.
  "ordering" INTEGER NOT NULL DEFAULT 0 -- column used to sort the rows before iterating over them to build the query
);
