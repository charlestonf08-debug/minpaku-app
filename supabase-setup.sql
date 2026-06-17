-- ==========================================
-- 民泊運営管理システム - Supabase Schema
-- ==========================================

-- Enable RLS
-- Run this in the Supabase SQL Editor

-- Properties (物件マスタ)
CREATE TABLE IF NOT EXISTS properties (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('joint', 'solo')),
  revenue_owner TEXT NOT NULL CHECK (revenue_owner IN ('kawaken', 'ryoko')),
  include_settlement BOOLEAN DEFAULT true,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Staff (スタッフマスタ)
CREATE TABLE IF NOT EXISTS staff (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('kawaken', 'ryoko', 'external')),
  active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Staff transport fees (スタッフ × 物件 交通費)
CREATE TABLE IF NOT EXISTS staff_transport_fees (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  staff_id UUID REFERENCES staff(id) ON DELETE CASCADE,
  property_id UUID REFERENCES properties(id) ON DELETE CASCADE,
  amount INTEGER DEFAULT 0,
  UNIQUE(staff_id, property_id)
);

-- Cleaning shifts (清掃シフト)
CREATE TABLE IF NOT EXISTS cleaning_shifts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  date DATE NOT NULL,
  property_id UUID REFERENCES properties(id) ON DELETE CASCADE,
  status TEXT DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'completed')),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Cleaning shift staff (シフト × スタッフ 中間テーブル)
CREATE TABLE IF NOT EXISTS cleaning_shift_staff (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shift_id UUID REFERENCES cleaning_shifts(id) ON DELETE CASCADE,
  staff_id UUID REFERENCES staff(id) ON DELETE CASCADE,
  cleaning_fee INTEGER DEFAULT 0,
  transport_fee INTEGER DEFAULT 0,
  total_fee INTEGER DEFAULT 0
);

-- Monthly revenue (月次売上)
CREATE TABLE IF NOT EXISTS monthly_revenue (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id UUID REFERENCES properties(id) ON DELETE CASCADE,
  year INTEGER NOT NULL,
  month INTEGER NOT NULL,
  amount INTEGER DEFAULT 0,
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(property_id, year, month)
);

-- Monthly fixed expenses (月次固定費)
CREATE TABLE IF NOT EXISTS monthly_fixed_expenses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id UUID REFERENCES properties(id) ON DELETE CASCADE,
  year INTEGER NOT NULL,
  month INTEGER NOT NULL,
  category TEXT NOT NULL,
  amount INTEGER DEFAULT 0,
  payer TEXT DEFAULT 'kawaken',
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Monthly variable expenses (月次変動費)
CREATE TABLE IF NOT EXISTS monthly_variable_expenses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id UUID REFERENCES properties(id) ON DELETE CASCADE,
  year INTEGER NOT NULL,
  month INTEGER NOT NULL,
  category TEXT NOT NULL CHECK (category IN ('消耗品', '備品', '特別費', 'その他')),
  amount INTEGER DEFAULT 0,
  payer TEXT NOT NULL CHECK (payer IN ('kawaken', 'ryoko')),
  memo TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Month locks (月次ロック)
CREATE TABLE IF NOT EXISTS month_locks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  year INTEGER NOT NULL,
  month INTEGER NOT NULL,
  locked_by TEXT,
  locked_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(year, month)
);

-- ==========================================
-- Initial Data (初期データ)
-- ==========================================

-- Properties
INSERT INTO properties (name, type, revenue_owner, include_settlement, sort_order) VALUES
  ('山王', 'joint', 'kawaken', true, 1),
  ('玉津', 'joint', 'ryoko', true, 2),
  ('橘', 'solo', 'kawaken', false, 3)
ON CONFLICT DO NOTHING;

-- Staff (かわけん・りょうこ)
INSERT INTO staff (name, type, active) VALUES
  ('かわけん', 'kawaken', true),
  ('りょうこ', 'ryoko', true)
ON CONFLICT DO NOTHING;

-- ==========================================
-- Row Level Security (RLS) Policies
-- ==========================================

ALTER TABLE properties ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff_transport_fees ENABLE ROW LEVEL SECURITY;
ALTER TABLE cleaning_shifts ENABLE ROW LEVEL SECURITY;
ALTER TABLE cleaning_shift_staff ENABLE ROW LEVEL SECURITY;
ALTER TABLE monthly_revenue ENABLE ROW LEVEL SECURITY;
ALTER TABLE monthly_fixed_expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE monthly_variable_expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE month_locks ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to read/write all tables
CREATE POLICY "Authenticated users can do everything" ON properties FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated users can do everything" ON staff FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated users can do everything" ON staff_transport_fees FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated users can do everything" ON cleaning_shifts FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated users can do everything" ON cleaning_shift_staff FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated users can do everything" ON monthly_revenue FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated users can do everything" ON monthly_fixed_expenses FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated users can do everything" ON monthly_variable_expenses FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated users can do everything" ON month_locks FOR ALL TO authenticated USING (true) WITH CHECK (true);
