-- Row-Level Security Policies for saigeetams schema

ALTER TABLE saigeetams.classes ENABLE ROW LEVEL SECURITY;
CREATE POLICY teacher_own_classes ON saigeetams.classes
  USING (teacher_id = auth.uid());

ALTER TABLE saigeetams.class_sessions ENABLE ROW LEVEL SECURITY;
CREATE POLICY session_access ON saigeetams.class_sessions
  USING (
    teacher_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM saigeetams.class_enrollments ce
      WHERE ce.class_id = class_sessions.class_id
        AND ce.student_id = auth.uid()
        AND ce.status = 'active'
    )
  );

ALTER TABLE saigeetams.progress_notes ENABLE ROW LEVEL SECURITY;
CREATE POLICY note_access ON saigeetams.progress_notes
  USING (
    teacher_id = auth.uid()
    OR student_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM saigeetams.parent_guardians pg
      WHERE pg.student_id = progress_notes.student_id
        AND pg.user_id = auth.uid()
    )
  );

ALTER TABLE saigeetams.attendance ENABLE ROW LEVEL SECURITY;
CREATE POLICY attendance_access ON saigeetams.attendance
  USING (
    student_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM saigeetams.class_sessions cs
      WHERE cs.id = attendance.session_id AND cs.teacher_id = auth.uid()
    )
    OR EXISTS (
      SELECT 1 FROM saigeetams.parent_guardians pg
      WHERE pg.student_id = attendance.student_id AND pg.user_id = auth.uid()
    )
  );

ALTER TABLE saigeetams.practice_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY practice_log_access ON saigeetams.practice_logs
  USING (
    student_id = auth.uid()
    OR teacher_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM saigeetams.parent_guardians pg
      WHERE pg.student_id = practice_logs.student_id AND pg.user_id = auth.uid()
    )
  );

ALTER TABLE saigeetams.student_skills ENABLE ROW LEVEL SECURITY;
CREATE POLICY skill_access ON saigeetams.student_skills
  USING (
    student_id = auth.uid()
    OR teacher_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM saigeetams.parent_guardians pg
      WHERE pg.student_id = student_skills.student_id AND pg.user_id = auth.uid()
    )
  );

ALTER TABLE saigeetams.student_badges ENABLE ROW LEVEL SECURITY;
CREATE POLICY badge_access ON saigeetams.student_badges
  USING (
    student_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM saigeetams.parent_guardians pg
      WHERE pg.student_id = student_badges.student_id AND pg.user_id = auth.uid()
    )
  );

ALTER TABLE saigeetams.report_cards ENABLE ROW LEVEL SECURITY;
CREATE POLICY report_card_access ON saigeetams.report_cards
  USING (
    student_id = auth.uid()
    OR teacher_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM saigeetams.parent_guardians pg
      WHERE pg.student_id = report_cards.student_id AND pg.user_id = auth.uid()
    )
  );

ALTER TABLE saigeetams.submissions ENABLE ROW LEVEL SECURITY;
CREATE POLICY submission_access ON saigeetams.submissions
  USING (
    student_id = auth.uid()
    OR teacher_id = auth.uid()
  );

ALTER TABLE saigeetams.makeup_requests ENABLE ROW LEVEL SECURITY;
CREATE POLICY makeup_request_access ON saigeetams.makeup_requests
  USING (
    student_id = auth.uid()
    OR teacher_id = auth.uid()
  );

ALTER TABLE saigeetams.message_responses ENABLE ROW LEVEL SECURITY;
CREATE POLICY message_response_access ON saigeetams.message_responses
  USING (
    student_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM saigeetams.messages m
      WHERE m.id = message_responses.message_id AND m.teacher_id = auth.uid()
    )
  );

ALTER TABLE saigeetams.materials ENABLE ROW LEVEL SECURITY;
CREATE POLICY material_access ON saigeetams.materials
  USING (
    teacher_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM saigeetams.class_sessions cs
      JOIN saigeetams.class_enrollments ce ON ce.class_id = cs.class_id
      WHERE cs.id = materials.session_id
        AND ce.student_id = auth.uid()
        AND ce.status = 'active'
    )
  );

ALTER TABLE saigeetams.messages ENABLE ROW LEVEL SECURITY;
CREATE POLICY message_access ON saigeetams.messages
  USING (
    teacher_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM saigeetams.class_enrollments ce
      WHERE ce.class_id = messages.class_id
        AND ce.student_id = auth.uid()
        AND ce.status = 'active'
    )
  );

ALTER TABLE saigeetams.class_enrollments ENABLE ROW LEVEL SECURITY;
CREATE POLICY enrollment_access ON saigeetams.class_enrollments
  USING (
    student_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM saigeetams.classes c
      WHERE c.id = class_enrollments.class_id AND c.teacher_id = auth.uid()
    )
  );

ALTER TABLE saigeetams.parent_guardians ENABLE ROW LEVEL SECURITY;
CREATE POLICY parent_access ON saigeetams.parent_guardians
  USING (
    user_id = auth.uid()
    OR student_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM saigeetams.class_enrollments ce
      JOIN saigeetams.classes c ON c.id = ce.class_id
      WHERE ce.student_id = parent_guardians.student_id AND c.teacher_id = auth.uid()
    )
  );

ALTER TABLE saigeetams.consent_forms ENABLE ROW LEVEL SECURITY;
CREATE POLICY consent_access ON saigeetams.consent_forms
  USING (
    student_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM saigeetams.parent_guardians pg
      WHERE pg.student_id = consent_forms.student_id AND pg.user_id = auth.uid()
    )
    OR EXISTS (
      SELECT 1 FROM saigeetams.class_enrollments ce
      JOIN saigeetams.classes c ON c.id = ce.class_id
      WHERE ce.student_id = consent_forms.student_id AND c.teacher_id = auth.uid()
    )
  );

ALTER TABLE saigeetams.invitation_links ENABLE ROW LEVEL SECURITY;
CREATE POLICY invite_access ON saigeetams.invitation_links
  USING (teacher_id = auth.uid());

ALTER TABLE saigeetams.push_tokens ENABLE ROW LEVEL SECURITY;
CREATE POLICY push_token_access ON saigeetams.push_tokens
  USING (user_id = auth.uid());

ALTER TABLE saigeetams.terms ENABLE ROW LEVEL SECURITY;
CREATE POLICY term_access ON saigeetams.terms
  USING (teacher_id = auth.uid());

ALTER TABLE saigeetams.users ENABLE ROW LEVEL SECURITY;
CREATE POLICY user_self_access ON saigeetams.users
  USING (id = auth.uid());
CREATE POLICY user_teacher_access ON saigeetams.users
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM saigeetams.class_enrollments ce
      JOIN saigeetams.classes c ON c.id = ce.class_id
      WHERE ce.student_id = users.id AND c.teacher_id = auth.uid()
    )
  );
