-- FIX: Add missing 'notes' column to feeds table
ALTER TABLE public.feeds 
ADD COLUMN IF NOT EXISTS notes text;

-- Verify policies (optional but good practice)
-- Ensure RLS allows update/insert on this new column (implicitly covered by table policy)
