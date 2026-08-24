-- Complete fix for profiles table compatibility with reviews
-- Run this in Supabase SQL Editor

-- Step 1: Check if profiles table exists and its structure
DO $$ 
BEGIN
    -- Check if name column exists, if not add it
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' 
        AND column_name = 'name' 
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE profiles ADD COLUMN name TEXT;
        RAISE NOTICE 'Added name column to profiles';
    END IF;

    -- Check if email column exists, if not add it
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' 
        AND column_name = 'email' 
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE profiles ADD COLUMN email TEXT;
        RAISE NOTICE 'Added email column to profiles';
    END IF;
END $$;

-- Step 2: Populate name and email from auth.users if they're empty
UPDATE profiles p
SET 
    name = COALESCE(p.name, au.raw_user_meta_data->>'name', au.email),
    email = COALESCE(p.email, au.email)
FROM auth.users au
WHERE p.id = au.id 
AND (p.name IS NULL OR p.email IS NULL);

-- Step 3: Set defaults for any remaining NULL values
UPDATE profiles
SET 
    name = COALESCE(name, 'User'),
    email = COALESCE(email, 'user@example.com')
WHERE name IS NULL OR email IS NULL;

-- Step 4: Verify the fix
SELECT 
    COUNT(*) as total_profiles,
    COUNT(name) as profiles_with_name,
    COUNT(email) as profiles_with_email
FROM profiles;

-- Success message
SELECT 'Profiles table is now compatible with reviews system!' as status;
