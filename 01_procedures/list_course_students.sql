-- =============================================================
-- list_course_students
-- Lists all students in a course.
-- Concepts: procedure, explicit cursor with a PARAMETER,
--           cursor FOR loop, calling a function
-- =============================================================
CREATE OR REPLACE PROCEDURE list_course_students (
  p_course_id IN courses.course_id%TYPE
)
IS
  CURSOR c_students (cp_course_id NUMBER) IS
    SELECT s.student_id, s.full_name, e.score, e.grade
      FROM enrollments e
      JOIN students s ON s.student_id = e.student_id
     WHERE e.course_id = cp_course_id
     ORDER BY s.full_name;

  v_total NUMBER;
BEGIN
  -- Raises ORA-20009 if the course does not exist
  v_total := count_students_in_course(p_course_id);

  DBMS_OUTPUT.PUT_LINE('Students in course ' || p_course_id || ' (total: ' || v_total || ')');

  -- Cursor FOR loop: Oracle opens, fetches and closes the cursor automatically
  FOR r IN c_students(p_course_id) LOOP
    DBMS_OUTPUT.PUT_LINE(' - ' || RPAD(r.full_name, 25) ||
                         ' score: ' || RPAD(NVL(TO_CHAR(r.score), '-'), 6) ||
                         ' grade: ' || NVL(r.grade, '-'));
  END LOOP;
END list_course_students;
/
