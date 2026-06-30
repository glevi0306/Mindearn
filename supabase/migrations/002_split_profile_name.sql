-- ================================================================
-- MindEarn – split profile name into first_name / last_name
-- Migration : 002_split_profile_name.sql
-- Run via   : Supabase Dashboard → SQL Editor → New query → Run
-- Depends on: 001_initial_schema.sql (profiles table must exist)
-- ================================================================

BEGIN;


-- ----------------------------------------------------------------
-- §1  ADD COLUMNS
-- ----------------------------------------------------------------

ALTER TABLE public.profiles
  ADD COLUMN first_name text,
  ADD COLUMN last_name  text;


-- ----------------------------------------------------------------
-- §2  BACKFILL existing rows from the name column
--     first word  → first_name
--     remainder   → last_name  (NULL when name was a single word)
-- ----------------------------------------------------------------

UPDATE public.profiles
SET
  first_name = SPLIT_PART(TRIM(name), ' ', 1),
  last_name  = CASE
    WHEN TRIM(name) LIKE '% %'
    THEN TRIM(SUBSTRING(TRIM(name) FROM POSITION(' ' IN TRIM(name)) + 1))
    ELSE NULL
  END
WHERE name IS NOT NULL AND TRIM(name) <> '';


-- ----------------------------------------------------------------
-- §3  REPLACE handle_new_user() to store first_name and last_name
--
--     Registration now sends metadata keys:
--       first_name  – Keresztnév (given name)
--       last_name   – Vezetéknév (family name)
--       name        – "${first_name} ${last_name}" (fallback full name)
--
--     Backward-compatible: old sign-ups that only sent "name" still
--     get a profiles row with name filled, first_name/last_name NULL.
-- ----------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public AS $$
DECLARE
  v_first_name text;
  v_last_name  text;
  v_name       text;
BEGIN
  v_first_name := NULLIF(TRIM(COALESCE(NEW.raw_user_meta_data->>'first_name', '')), '');
  v_last_name  := NULLIF(TRIM(COALESCE(NEW.raw_user_meta_data->>'last_name',  '')), '');

  -- Prefer the explicit "name" key; fall back to constructing it.
  v_name := NULLIF(TRIM(COALESCE(
    NULLIF(TRIM(COALESCE(NEW.raw_user_meta_data->>'name', '')), ''),
    CONCAT_WS(' ', v_last_name, v_first_name)
  )), '');

  INSERT INTO public.profiles (id, name, first_name, last_name)
    VALUES (NEW.id, v_name, v_first_name, v_last_name)
    ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.user_access (user_id, resource, status)
    VALUES
      (NEW.id, 'book',     'active'),
      (NEW.id, 'workbook', 'active'),
      (NEW.id, 'course',   'building'),
      (NEW.id, 'audio',    'building'),
      (NEW.id, 'live',     'planned')
    ON CONFLICT (user_id, resource) DO NOTHING;

  RETURN NEW;
END;
$$;


COMMIT;
