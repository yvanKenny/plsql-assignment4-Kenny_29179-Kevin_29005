-- =============================================================
-- test_success_cases.sql
-- Each test should run WITHOUT errors.
-- Run after: tables -> sample data -> functions -> procedures
-- =============================================================
SET SERVEROUTPUT ON;

-- TEST S1: add_student (INSERT + SQL%ROWCOUNT)
DECLARE
  v_rows NUMBER;
BEGIN
  DBMS_OUTPUT.PUT_LINE('=== TEST S1: add_student ===');
  add_student(9, 'Kevin Manzi', 'kevin.manzi@auca.ac.rw', v_rows);
END;
/

-- TEST S2: update_score (UPDATE + SQL%FOUND)
DECLARE
  v_rows NUMBER;
BEGIN
  DBMS_OUTPUT.PUT_LINE('=== TEST S2: update_score ===');
  update_score(1, 10, 92, v_rows);
END;
/

-- TEST S3: bulk_enroll (FORALL INSERT, all succeed)
DECLARE
  v_ok  NUMBER;
  v_err NUMBER;
BEGIN
  DBMS_OUTPUT.PUT_LINE('=== TEST S3: bulk_enroll ===');
  bulk_enroll(10, t_id_list(3, 4, 5), v_ok, v_err);
  DBMS_OUTPUT.PUT_LINE('OK: ' || v_ok || ', errors: ' || v_err);
END;
/

-- TEST S4: compute_course_grades (BULK COLLECT + FORALL UPDATE + associative array)
DECLARE
  v_updated NUMBER;
BEGIN
  DBMS_OUTPUT.PUT_LINE('=== TEST S4: compute_course_grades ===');
  compute_course_grades(10, v_updated);
  compute_course_grades(11, v_updated);
  compute_course_grades(12, v_updated);
END;
/

-- TEST S5: print_transcript (user-defined record + explicit cursor)
BEGIN
  DBMS_OUTPUT.PUT_LINE('=== TEST S5: print_transcript ===');
  print_transcript(1);
END;
/

-- TEST S6: list_course_students (cursor FOR loop with parameter)
BEGIN
  DBMS_OUTPUT.PUT_LINE('=== TEST S6: list_course_students ===');
  list_course_students(10);
END;
/

-- TEST S7: functions called from an anonymous block
DECLARE
  v_id NUMBER;
BEGIN
  DBMS_OUTPUT.PUT_LINE('=== TEST S7: functions ===');
  DBMS_OUTPUT.PUT_LINE('Average of student 1: ' || get_student_average(1));
  v_id := find_student_id_by_name('Habimana');
  DBMS_OUTPUT.PUT_LINE('ID of "Habimana": ' || v_id);
  DBMS_OUTPUT.PUT_LINE('Students in course 10: ' || count_students_in_course(10));
END;
/

-- TEST S8: function called from a SQL statement
SELECT s.full_name, c.course_code, e.score, score_to_grade(e.score) AS computed_grade
  FROM enrollments e
  JOIN students s ON s.student_id = e.student_id
  JOIN courses  c ON c.course_id  = e.course_id
 WHERE e.score IS NOT NULL
 ORDER BY s.full_name, c.course_code;

-- TEST S9: delete_enrollment (DELETE + SQL%ROWCOUNT)
DECLARE
  v_rows NUMBER;
BEGIN
  DBMS_OUTPUT.PUT_LINE('=== TEST S9: delete_enrollment ===');
  delete_enrollment(5, 10, v_rows);
END;
/
