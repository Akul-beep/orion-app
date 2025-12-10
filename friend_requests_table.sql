-- ============================================
-- FRIEND REQUESTS TABLE
-- Add this to your Supabase SQL Editor
-- ============================================

-- Friend requests table
CREATE TABLE IF NOT EXISTS friend_requests (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  from_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  from_display_name TEXT,
  from_photo_url TEXT,
  to_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending', -- 'pending', 'accepted', 'rejected'
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(from_user_id, to_user_id)
);

-- Enable RLS
ALTER TABLE friend_requests ENABLE ROW LEVEL SECURITY;

-- RLS Policies
DO $$ 
BEGIN
  -- Users can see requests they sent or received
  -- Added text casting for better UUID comparison compatibility
  DROP POLICY IF EXISTS "Users can view own friend requests" ON friend_requests;
  CREATE POLICY "Users can view own friend requests" ON friend_requests
    FOR SELECT USING (
      auth.uid() = from_user_id OR 
      auth.uid() = to_user_id OR
      from_user_id::text = auth.uid()::text OR
      to_user_id::text = auth.uid()::text
    );

  -- Users can create requests (send)
  DROP POLICY IF EXISTS "Users can send friend requests" ON friend_requests;
  CREATE POLICY "Users can send friend requests" ON friend_requests
    FOR INSERT WITH CHECK (
      auth.uid() = from_user_id OR
      from_user_id::text = auth.uid()::text
    );

  -- Users can update requests they received (accept/reject)
  DROP POLICY IF EXISTS "Users can update received requests" ON friend_requests;
  CREATE POLICY "Users can update received requests" ON friend_requests
    FOR UPDATE USING (
      auth.uid() = to_user_id OR
      to_user_id::text = auth.uid()::text
    );

  -- Users can delete requests they sent (cancel)
  DROP POLICY IF EXISTS "Users can delete sent requests" ON friend_requests;
  CREATE POLICY "Users can delete sent requests" ON friend_requests
    FOR DELETE USING (
      auth.uid() = from_user_id OR
      from_user_id::text = auth.uid()::text
    );
END $$;

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_friend_requests_from_user_id ON friend_requests(from_user_id);
CREATE INDEX IF NOT EXISTS idx_friend_requests_to_user_id ON friend_requests(to_user_id);
CREATE INDEX IF NOT EXISTS idx_friend_requests_status ON friend_requests(status);

