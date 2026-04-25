-- Expose the saigeetams schema to PostgREST API
-- This is REQUIRED so the Supabase client can query saigeetams.* tables

-- Add saigeetams to the list of exposed schemas
ALTER ROLE authenticator SET pgrst.db_schemas = 'public, saigeetams';

-- Reload PostgREST config
NOTIFY pgrst, 'reload config';
