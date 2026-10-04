-- Integration schema: convert to an append-only Drizzle migration in the
-- existing account backend. Never run DDL during a public request.
CREATE TABLE app_email_enrollments (
  account_id TEXT NOT NULL,
  sequence TEXT NOT NULL,
  consent_at TEXT NOT NULL,
  consent_version TEXT NOT NULL,
  consent_text TEXT NOT NULL,
  state TEXT NOT NULL CHECK (state IN ('dispatching','accepted','review_required')),
  updated_at TEXT NOT NULL,
  PRIMARY KEY (account_id, sequence)
);
