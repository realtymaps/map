DROP TABLE IF EXISTS view_status;
CREATE TABLE view_status (
  "view_id" TEXT NOT NULL PRIMARY KEY, -- the identifier of the dynamic view this row tracks
  "dirty" BOOLEAN NOT NULL, -- whether this view has any changes that need to be staged
  "dirty_breaking" BOOLEAN NOT NULL DEFAULT FALSE, -- whether any of this view's dirty changes are breaking (i.e. need to wait for an app startup)
  "staged" BOOLEAN NOT NULL DEFAULT FALSE, -- whether this view has any staged changes
  "staged_breaking" BOOLEAN NOT NULL DEFAULT FALSE -- whether any of this view's staged changes are breaking (i.e. need to wait for an app startup)
);
