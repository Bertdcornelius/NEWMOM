-- FIX: Add missing image_url column to milestones table
ALTER TABLE public.milestones ADD COLUMN IF NOT EXISTS image_url text;
