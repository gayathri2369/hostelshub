// ──────────────────────────────────────────────────────────────────────────────
// Supabase Configuration
//
// SETUP STEPS:
//   1. Go to https://supabase.com → New Project
//   2. Run supabase_schema.sql in SQL Editor
//   3. Go to Settings → API
//   4. Copy "Project URL" → paste as supabaseUrl below
//   5. Copy "anon public" key → paste as supabaseAnonKey below
// ──────────────────────────────────────────────────────────────────────────────

class SupabaseConfig {
  // ⚠️  Replace with your actual Supabase project values
  // Settings → API → Project URL
  static const String supabaseUrl      = 'https://hiommpywjxtmaekkmhkn.supabase.co';
  // Settings → API → Project API keys → anon / public
  static const String supabaseAnonKey  = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhpb21tcHl3anh0bWFla2ttaGtuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODYwNjgzMDMsImV4cCI6MjEwMTY0NDMwM30.pTpR13KPbmM2hZ8m_ngPkktKOX4YNv6b28aCrX1ujxo';

  // ── Auto-detect if real credentials have been set ─────────────────────────
  static bool get isConfigured =>
      !supabaseUrl.contains('YOUR_PROJECT_ID') &&
      !supabaseAnonKey.contains('YOUR_ANON_PUBLIC_KEY') &&
      supabaseUrl.startsWith('https://') &&
      supabaseUrl.endsWith('.supabase.co');

  // Table names
  static const String profilesTable      = 'profiles';
  static const String productsTable      = 'products';
  static const String wishlistsTable     = 'wishlists';
  static const String conversationsTable = 'conversations';
  static const String messagesTable      = 'messages';
  
  // Storage
  static const String productImagesBucket = 'product-images';
}
