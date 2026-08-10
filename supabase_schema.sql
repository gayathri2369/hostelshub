-- ============================================================
-- HostelHub Supabase Schema
-- Run this entire file in Supabase → SQL Editor
-- ============================================================

-- ── 1. profiles (extends auth.users) ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.profiles (
  id          UUID        PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name        TEXT        NOT NULL DEFAULT '',
  phone       TEXT        NOT NULL DEFAULT '',
  role        TEXT        NOT NULL DEFAULT 'buyer' CHECK (role IN ('buyer','seller')),
  hostel_name TEXT        NOT NULL DEFAULT '',
  room_number TEXT        NOT NULL DEFAULT '',
  avatar_url  TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view all profiles"
  ON public.profiles FOR SELECT USING (true);

CREATE POLICY "Users can insert own profile"
  ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- Auto-create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  INSERT INTO public.profiles (id, name, phone, role, hostel_name, room_number)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'name', ''),
    COALESCE(NEW.raw_user_meta_data->>'phone', ''),
    COALESCE(NEW.raw_user_meta_data->>'role', 'buyer'),
    COALESCE(NEW.raw_user_meta_data->>'hostel_name', ''),
    COALESCE(NEW.raw_user_meta_data->>'room_number', '')
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ── 2. products ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.products (
  id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  title        TEXT        NOT NULL,
  description  TEXT        NOT NULL DEFAULT '',
  category     TEXT        NOT NULL DEFAULT 'other',
  price        NUMERIC     NOT NULL DEFAULT 0,
  image_urls   TEXT[]      NOT NULL DEFAULT '{}',
  seller_id    UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  seller_name  TEXT        NOT NULL DEFAULT '',
  seller_hostel TEXT       NOT NULL DEFAULT '',
  seller_phone TEXT        NOT NULL DEFAULT '',
  status       TEXT        NOT NULL DEFAULT 'available' CHECK (status IN ('available','sold','reserved')),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view available products"
  ON public.products FOR SELECT USING (true);

CREATE POLICY "Sellers can insert own products"
  ON public.products FOR INSERT WITH CHECK (auth.uid() = seller_id);

CREATE POLICY "Sellers can update own products"
  ON public.products FOR UPDATE USING (auth.uid() = seller_id);

CREATE POLICY "Sellers can delete own products"
  ON public.products FOR DELETE USING (auth.uid() = seller_id);

-- Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE public.products;

-- ── 3. wishlists ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.wishlists (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, product_id)
);

ALTER TABLE public.wishlists ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own wishlist"
  ON public.wishlists FOR ALL USING (auth.uid() = user_id);

-- ── 4. conversations ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.conversations (
  id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id    UUID        NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  product_title TEXT        NOT NULL DEFAULT '',
  buyer_id      UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  buyer_name    TEXT        NOT NULL DEFAULT '',
  seller_id     UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  seller_name   TEXT        NOT NULL DEFAULT '',
  last_updated  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (product_id, buyer_id)
);

ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Participants can view own conversations"
  ON public.conversations FOR SELECT
  USING (auth.uid() = buyer_id OR auth.uid() = seller_id);

CREATE POLICY "Buyer can create conversation"
  ON public.conversations FOR INSERT WITH CHECK (auth.uid() = buyer_id);

CREATE POLICY "Participants can update conversation"
  ON public.conversations FOR UPDATE
  USING (auth.uid() = buyer_id OR auth.uid() = seller_id);

ALTER PUBLICATION supabase_realtime ADD TABLE public.conversations;

-- ── 5. messages ───────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.messages (
  id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID        NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
  sender_id       UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  sender_name     TEXT        NOT NULL DEFAULT '',
  text            TEXT        NOT NULL,
  is_read         BOOLEAN     NOT NULL DEFAULT FALSE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Conversation participants can view messages"
  ON public.messages FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.conversations c
      WHERE c.id = conversation_id
        AND (c.buyer_id = auth.uid() OR c.seller_id = auth.uid())
    )
  );

CREATE POLICY "Conversation participants can insert messages"
  ON public.messages FOR INSERT
  WITH CHECK (
    auth.uid() = sender_id AND
    EXISTS (
      SELECT 1 FROM public.conversations c
      WHERE c.id = conversation_id
        AND (c.buyer_id = auth.uid() OR c.seller_id = auth.uid())
    )
  );

CREATE POLICY "Recipients can mark messages read"
  ON public.messages FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.conversations c
      WHERE c.id = conversation_id
        AND (c.buyer_id = auth.uid() OR c.seller_id = auth.uid())
    )
  );

ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;

-- ── Indexes for performance ────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_products_seller ON public.products(seller_id);
CREATE INDEX IF NOT EXISTS idx_products_status ON public.products(status);
CREATE INDEX IF NOT EXISTS idx_products_category ON public.products(category);
CREATE INDEX IF NOT EXISTS idx_wishlists_user ON public.wishlists(user_id);
CREATE INDEX IF NOT EXISTS idx_conversations_buyer ON public.conversations(buyer_id);
CREATE INDEX IF NOT EXISTS idx_conversations_seller ON public.conversations(seller_id);
CREATE INDEX IF NOT EXISTS idx_messages_conversation ON public.messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_created ON public.messages(created_at);
