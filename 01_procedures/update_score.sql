-- =============================================================
-- update_score
-- Updates the score (and grade) of a student in a course.
-- Concepts: procedure, IN/OUT parameters, implicit cursor (UPDATE),
--           SQL%ROWCOUNT, SQL%FOUND, SQL%NOTFOUND,
--           user-defined exception, RAISE_APPLICATION_ERROR
-- =============================================================
CREATE OR REPLACE PROCEDURE update_score (
  p_student_id   IN  enrollments.student_id%TYPE,
  p_course_id    IN  enrollments.course_id%TYPE,
  p_score        IN  enrollments.score%TYPE,
  p_rows_updated OUT NUMBER
)
IS
  e_invalid_score EXCEPTION;          -- user-defined exception
BEGIN
  IF p_score IS NULL OR p_score < 0 OR p_score > 100 THEN
    RAISE e_invalid_score;
  END IF;

  UPDATE enrollments
     SET score = p_score,
         grade = score_to_grade(p_score)
   WHERE student_id = p_student_id
     AND course_id  = p_course_id;

  p_rows_updated := SQL%ROWCOUNT;

  IF SQL%NOTFOUND THEN
    RAISE_APPLICATION_ERROR(-20002, 'Student ' || p_student_id ||
                                    ' is not enrolled in course ' || p_course_id || '.');
  ELSIF SQL%FOUND THEN
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Score updated to ' || p_score || '. Rows updated: ' || p_rows_updated);
  END IF;
EXCEPTION
  WHEN e_invalid_score THEN
    RAISE_APPLICATION_ERROR(-20003, 'Score must be between 0 and 100. Given: ' ||
                                    NVL(TO_CHAR(p_score), 'NULL'));
END update_score;
/
