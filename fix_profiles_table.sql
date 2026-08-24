-- Fix profiles table for review system compatibility
-- Run this in Supabase SQL Editor

-- Check current profiles table structure
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'profiles' AND table_schema = 'public';

-- If you see the profiles table doesn't have 'name' and 'email' columns, 
-- you might need to add them or use the auth.users table

-- Option 1: Add missing columns to profiles if needed
-- ALTER TABLE profiles ADD COLUMN IF NOT EXISTS name TEXT;
-- ALTER TABLE profiles ADD COLUMN IF NOT EXISTS email TEXT;

-- Option 2: Verify profiles table has the right structure
-- The profiles table should have at least: id, name, email

-- If your profiles table has different column names, 
-- you may need to update the review queries in ReviewProvider

-- Show current profiles table structure
SELECT * FROM profiles LIMIT 1;
