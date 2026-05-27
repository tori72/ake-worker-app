-- ============================================================
-- AKE Worker App - Inventory Management Database Schema
-- Run these statements in your Supabase SQL Editor
-- ============================================================

-- ─────────────────────────────────────────────
-- LOOKUP / DROPDOWN TABLES
-- ─────────────────────────────────────────────

-- Items (product names)
CREATE TABLE IF NOT EXISTS items (
  id   SERIAL PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Threads
CREATE TABLE IF NOT EXISTS threads (
  id   SERIAL PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Lengths
CREATE TABLE IF NOT EXISTS lengths (
  id    SERIAL PRIMARY KEY,
  value TEXT NOT NULL UNIQUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Heads
CREATE TABLE IF NOT EXISTS heads (
  id   SERIAL PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Colours
CREATE TABLE IF NOT EXISTS colours (
  id   SERIAL PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─────────────────────────────────────────────
-- MAIN TRANSACTION TABLE
-- ─────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS sales_transactions (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  date        DATE        NOT NULL DEFAULT CURRENT_DATE,
  party       TEXT        NOT NULL,

  -- Item details (foreign keys to lookup tables)
  item_id     INTEGER     REFERENCES items(id),
  thread_id   INTEGER     REFERENCES threads(id),
  length_id   INTEGER     REFERENCES lengths(id),
  head_id     INTEGER     REFERENCES heads(id),
  colour_id   INTEGER     REFERENCES colours(id),

  -- Transaction details
  quantity    INTEGER     NOT NULL CHECK (quantity > 0),
  uom         TEXT        NOT NULL CHECK (uom IN ('5', 'Gross', 'KH', 'Pcs', 'Box')),
  rate        NUMERIC(12, 2) NOT NULL CHECK (rate >= 0),
  mode        TEXT        NOT NULL CHECK (mode IN ('cash', 'online', 'credit-slip', 'gst-cash', 'gst-bank', 'gst-credit')),
  amount      NUMERIC(14, 2) GENERATED ALWAYS AS (quantity * rate) STORED,

  -- Metadata
  location    TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON sales_transactions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ─────────────────────────────────────────────
-- SEED DATA (sample dropdown options)
-- ─────────────────────────────────────────────

INSERT INTO items (name) VALUES
  ('Screw M4'), ('Screw M6'), ('Bolt M8'), ('Nut M4'), ('Washer')
ON CONFLICT (name) DO NOTHING;

INSERT INTO threads (name) VALUES
  ('Metric'), ('Imperial'), ('UNC'), ('UNF'), ('BSW')
ON CONFLICT (name) DO NOTHING;

INSERT INTO lengths (value) VALUES
  ('10mm'), ('20mm'), ('30mm'), ('50mm'), ('100mm')
ON CONFLICT (value) DO NOTHING;

INSERT INTO heads (name) VALUES
  ('Hex'), ('Pan'), ('Round'), ('Flat'), ('Socket')
ON CONFLICT (name) DO NOTHING;

INSERT INTO colours (name) VALUES
  ('Natural'), ('Zinc Plated'), ('Black Oxide'), ('Hot Dip Galvanised'), ('Stainless')
ON CONFLICT (name) DO NOTHING;

-- ─────────────────────────────────────────────
-- ROW LEVEL SECURITY (enable in Supabase dashboard)
-- These policies allow the service_role key (used by backend) full access.
-- ─────────────────────────────────────────────

ALTER TABLE items               ENABLE ROW LEVEL SECURITY;
ALTER TABLE threads             ENABLE ROW LEVEL SECURITY;
ALTER TABLE lengths             ENABLE ROW LEVEL SECURITY;
ALTER TABLE heads               ENABLE ROW LEVEL SECURITY;
ALTER TABLE colours             ENABLE ROW LEVEL SECURITY;
ALTER TABLE sales_transactions  ENABLE ROW LEVEL SECURITY;

-- Service role bypass (backend uses service_role key — no RLS restrictions)
CREATE POLICY "service_role_all" ON items              FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "service_role_all" ON threads            FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "service_role_all" ON lengths            FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "service_role_all" ON heads              FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "service_role_all" ON colours            FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "service_role_all" ON sales_transactions FOR ALL TO service_role USING (true) WITH CHECK (true);
