-- =============================================================
-- get_student_average
-- Returns the average score of a student (NULL if no scores yet).
-- Concepts: function, %ROWTYPE record, %TYPE, NO_DATA_FOUND,
--           RAISE_APPLICATION_ERROR
-- =============================================================
CREATE OR REPLACE FUNCTION get_student_average (
  p_student_id IN students.student_id%TYPE
) RETURN NUMBER
IS
  v_student students%ROWTYPE;   -- record with the same columns as the STUDENTS table
  v_avg     NUMBER;
BEGIN
  -- 1. Make sure the student exists (raises NO_DATA_FOUND if not)
  SELECT * INTO v_student
    FROM students
   WHERE student_id = p_student_id;

  -- 2. Compute the average (AVG ignores NULL scores)
  SELECT AVG(score) INTO v_avg
    FROM enrollments
   WHERE student_id = p_student_id;

  -- NULL means "no scores yet" - we do NOT return 0, because 0 would be misleading.
  RETURN ROUND(v_avg, 2);
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20001, 'Student ' || p_student_id || ' does not exist.');
END get_student_average;
/
