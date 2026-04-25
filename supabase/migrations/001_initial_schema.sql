-- SAI GEETAMs Database Schema
-- Uses dedicated schema so multiple apps can share one Supabase project

CREATE SCHEMA IF NOT EXISTS saigeetams;

-- Grant access so PostgREST (Supabase API) can see the schema
GRANT USAGE ON SCHEMA saigeetams TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA saigeetams TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA saigeetams TO postgres, anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA saigeetams GRANT ALL ON TABLES TO postgres, anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA saigeetams GRANT ALL ON SEQUENCES TO postgres, anon, authenticated, service_role;

-- Expose schema via PostgREST
-- NOTE: Run this in Supabase Dashboard > Settings > API > Exposed schemas, add "saigeetams"
-- Or run: ALTER ROLE authenticator SET pgrst.db_schemas = 'public, saigeetams';
-- Then: NOTIFY pgrst, 'reload config';

CREATE TABLE saigeetams.users (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  role            TEXT NOT NULL CHECK (role IN ('teacher','student')),
  email           VARCHAR(255) UNIQUE,
  phone           VARCHAR(30),
  password_hash   VARCHAR(255),
  first_name      VARCHAR(100) NOT NULL,
  last_name       VARCHAR(100) NOT NULL,
  profile_photo   VARCHAR(500),
  dob             DATE,
  is_verified     BOOLEAN DEFAULT FALSE,
  is_approved     BOOLEAN DEFAULT FALSE,
  pin_hash        VARCHAR(255),
  biometrics_key  VARCHAR(255),
  created_at      TIMESTAMPTZ DEFAULT now(),
  updated_at      TIMESTAMPTZ DEFAULT now(),
  deleted_at      TIMESTAMPTZ
);

CREATE TABLE saigeetams.parent_guardians (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id        UUID NOT NULL REFERENCES saigeetams.users(id) ON DELETE CASCADE,
  user_id           UUID REFERENCES saigeetams.users(id),
  name              VARCHAR(200) NOT NULL,
  relationship      VARCHAR(50) NOT NULL,
  phone             VARCHAR(30) NOT NULL,
  email             VARCHAR(255),
  emergency_contact VARCHAR(30) NOT NULL,
  created_at        TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE saigeetams.consent_forms (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id     UUID NOT NULL REFERENCES saigeetams.users(id) ON DELETE CASCADE,
  signed_by      VARCHAR(200) NOT NULL,
  relationship   VARCHAR(50) NOT NULL,
  signed_at      TIMESTAMPTZ DEFAULT now(),
  form_version   VARCHAR(20) NOT NULL,
  signature_data TEXT NOT NULL,
  ip_address     VARCHAR(50)
);

CREATE TABLE saigeetams.classes (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  teacher_id  UUID NOT NULL REFERENCES saigeetams.users(id) ON DELETE CASCADE,
  title       VARCHAR(200) NOT NULL,
  description TEXT,
  color_code  VARCHAR(7),
  is_active   BOOLEAN DEFAULT TRUE,
  created_at  TIMESTAMPTZ DEFAULT now(),
  deleted_at  TIMESTAMPTZ
);

CREATE TABLE saigeetams.terms (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  teacher_id  UUID NOT NULL REFERENCES saigeetams.users(id),
  name        VARCHAR(100) NOT NULL,
  start_date  DATE NOT NULL,
  end_date    DATE NOT NULL,
  created_at  TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE saigeetams.class_sessions (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  class_id          UUID NOT NULL REFERENCES saigeetams.classes(id) ON DELETE CASCADE,
  teacher_id        UUID NOT NULL REFERENCES saigeetams.users(id),
  term_id           UUID REFERENCES saigeetams.terms(id),
  scheduled_date    DATE NOT NULL,
  start_time        TIME NOT NULL,
  end_time          TIME NOT NULL,
  status            TEXT DEFAULT 'active' CHECK (status IN ('active','cancelled','rescheduled')),
  cancellation_note TEXT,
  live_link         VARCHAR(500),
  substitute_name   VARCHAR(200),
  created_at        TIMESTAMPTZ DEFAULT now(),
  updated_at        TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE saigeetams.class_enrollments (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  class_id    UUID NOT NULL REFERENCES saigeetams.classes(id) ON DELETE CASCADE,
  student_id  UUID NOT NULL REFERENCES saigeetams.users(id) ON DELETE CASCADE,
  term_id     UUID REFERENCES saigeetams.terms(id),
  status      TEXT DEFAULT 'active' CHECK (status IN ('active','pending','removed','transferred','waitlist')),
  enrolled_at TIMESTAMPTZ DEFAULT now(),
  removed_at  TIMESTAMPTZ,
  UNIQUE(class_id, student_id)
);

CREATE TABLE saigeetams.attendance (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id      UUID NOT NULL REFERENCES saigeetams.class_sessions(id) ON DELETE CASCADE,
  student_id      UUID NOT NULL REFERENCES saigeetams.users(id) ON DELETE CASCADE,
  rsvp_status     TEXT DEFAULT 'no_response' CHECK (rsvp_status IN ('coming','not_coming','no_response')),
  actual_status   TEXT CHECK (actual_status IN ('present','absent','excused')),
  absence_reason  TEXT,
  rsvp_updated_at TIMESTAMPTZ,
  marked_at       TIMESTAMPTZ,
  UNIQUE(session_id, student_id)
);

CREATE TABLE saigeetams.makeup_requests (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id        UUID NOT NULL REFERENCES saigeetams.class_sessions(id),
  student_id        UUID NOT NULL REFERENCES saigeetams.users(id) ON DELETE CASCADE,
  teacher_id        UUID NOT NULL REFERENCES saigeetams.users(id),
  reason            TEXT,
  status            TEXT DEFAULT 'pending' CHECK (status IN ('pending','approved','declined')),
  makeup_date       DATE,
  makeup_session_id UUID REFERENCES saigeetams.class_sessions(id),
  created_at        TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE saigeetams.practice_logs (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id    UUID NOT NULL REFERENCES saigeetams.users(id) ON DELETE CASCADE,
  teacher_id    UUID NOT NULL REFERENCES saigeetams.users(id),
  log_date      DATE NOT NULL,
  duration_min  INT NOT NULL,
  notes         TEXT,
  approved      BOOLEAN,
  approved_at   TIMESTAMPTZ,
  created_at    TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE saigeetams.progress_notes (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id  UUID NOT NULL REFERENCES saigeetams.users(id) ON DELETE CASCADE,
  teacher_id  UUID NOT NULL REFERENCES saigeetams.users(id),
  session_id  UUID REFERENCES saigeetams.class_sessions(id),
  note_date   DATE NOT NULL,
  note        TEXT NOT NULL,
  created_at  TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE saigeetams.student_skills (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id  UUID NOT NULL REFERENCES saigeetams.users(id) ON DELETE CASCADE,
  teacher_id  UUID NOT NULL REFERENCES saigeetams.users(id),
  skill_name  VARCHAR(200) NOT NULL,
  level       INT DEFAULT 0 CHECK (level BETWEEN 0 AND 5),
  updated_at  TIMESTAMPTZ DEFAULT now(),
  UNIQUE(student_id, skill_name)
);

CREATE TABLE saigeetams.student_badges (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id  UUID NOT NULL REFERENCES saigeetams.users(id) ON DELETE CASCADE,
  badge_id    VARCHAR(50) NOT NULL,
  earned_at   TIMESTAMPTZ DEFAULT now(),
  UNIQUE(student_id, badge_id)
);

CREATE TABLE saigeetams.report_cards (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id     UUID NOT NULL REFERENCES saigeetams.users(id) ON DELETE CASCADE,
  teacher_id     UUID NOT NULL REFERENCES saigeetams.users(id),
  term_id        UUID REFERENCES saigeetams.terms(id),
  term_name      VARCHAR(100) NOT NULL,
  attendance_pct DECIMAL(5,2),
  overall_grade  VARCHAR(5),
  comments       TEXT,
  skill_grades   JSONB,
  is_shared      BOOLEAN DEFAULT FALSE,
  shared_at      TIMESTAMPTZ,
  created_at     TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE saigeetams.messages (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  teacher_id   UUID NOT NULL REFERENCES saigeetams.users(id),
  class_id     UUID REFERENCES saigeetams.classes(id),
  type         TEXT NOT NULL CHECK (type IN ('announcement','poll','cancellation','general')),
  title        VARCHAR(300),
  content      TEXT NOT NULL,
  requires_ack BOOLEAN DEFAULT FALSE,
  poll_options JSONB,
  created_at   TIMESTAMPTZ DEFAULT now(),
  expires_at   TIMESTAMPTZ
);

CREATE TABLE saigeetams.message_responses (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id   UUID NOT NULL REFERENCES saigeetams.messages(id) ON DELETE CASCADE,
  student_id   UUID NOT NULL REFERENCES saigeetams.users(id) ON DELETE CASCADE,
  response     TEXT CHECK (response IN ('acknowledged','accepted','rejected')),
  poll_choice  VARCHAR(200),
  responded_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(message_id, student_id)
);

CREATE TABLE saigeetams.materials (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id   UUID NOT NULL REFERENCES saigeetams.class_sessions(id) ON DELETE CASCADE,
  teacher_id   UUID NOT NULL REFERENCES saigeetams.users(id),
  title        VARCHAR(300) NOT NULL,
  file_url     VARCHAR(500) NOT NULL,
  file_type    TEXT CHECK (file_type IN ('image','pdf','note','audio','video')),
  file_size_kb INT,
  is_active    BOOLEAN DEFAULT TRUE,
  created_at   TIMESTAMPTZ DEFAULT now(),
  deleted_at   TIMESTAMPTZ
);

CREATE TABLE saigeetams.submissions (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id    UUID NOT NULL REFERENCES saigeetams.class_sessions(id),
  student_id    UUID NOT NULL REFERENCES saigeetams.users(id) ON DELETE CASCADE,
  teacher_id    UUID NOT NULL REFERENCES saigeetams.users(id),
  file_url      VARCHAR(500) NOT NULL,
  file_type     VARCHAR(50),
  file_size_kb  INT,
  teacher_note  TEXT,
  submitted_at  TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE saigeetams.invitation_links (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  class_id    UUID NOT NULL REFERENCES saigeetams.classes(id) ON DELETE CASCADE,
  teacher_id  UUID NOT NULL REFERENCES saigeetams.users(id),
  token       VARCHAR(100) UNIQUE NOT NULL,
  expires_at  TIMESTAMPTZ NOT NULL,
  max_uses    INT NOT NULL DEFAULT 50,
  used_count  INT NOT NULL DEFAULT 0,
  is_active   BOOLEAN DEFAULT TRUE,
  created_at  TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE saigeetams.push_tokens (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES saigeetams.users(id) ON DELETE CASCADE,
  token      VARCHAR(500) NOT NULL,
  platform   TEXT CHECK (platform IN ('ios','android')),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- At-risk students view
CREATE OR REPLACE VIEW saigeetams.at_risk_students AS
SELECT
  u.id AS student_id,
  u.first_name,
  u.last_name,
  COUNT(a.id) AS absences_last_30_days
FROM saigeetams.users u
JOIN saigeetams.attendance a ON a.student_id = u.id
JOIN saigeetams.class_sessions cs ON cs.id = a.session_id
WHERE a.actual_status = 'absent'
  AND cs.scheduled_date >= CURRENT_DATE - INTERVAL '30 days'
  AND u.role = 'student'
  AND u.deleted_at IS NULL
GROUP BY u.id, u.first_name, u.last_name
HAVING COUNT(a.id) >= 2;
