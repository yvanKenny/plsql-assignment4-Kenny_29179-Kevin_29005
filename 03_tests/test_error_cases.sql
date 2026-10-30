-- =============================================================
-- test_error_cases.sql
-- Each test SHOULD produce an error. The error is caught and printed,
-- which proves the exception handling works.
-- Run after test_success_cases.sql
-- =============================================================
SET SERVEROUTPUT ON;

-- TEST E1: student does not exist -> NO_DATA_FOUND -> ORA-20001
BEGIN
  DBMS_OUTPUT.PUT_LINE('=== TEST E1: unknown student (NO_DATA_FOUND) ===');
  print_transcript(999);
EXCEPTION
  WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
END;
/

-- TEST E2: name matches two students -> TOO_MANY_ROWS -> ORA-20008
DECLARE
  v_id NUMBER;
BEGIN
  DBMS_OUTPUT.PUT_LINE('=== TEST E2: ambiguous name (TOO_MANY_ROWS) ===');
  v_id := find_student_id_by_name('Alice');
EXCEPTION
  WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
END;
/

-- TEST E3: invalid score -> user-defined exception -> ORA-20003
DECLARE
  v_rows NUMBER;
BEGIN
  DBMS_OUTPUT.PUT_LINE('=== TEST E3: invalid score (user-defined exception) ===');
  update_score(1, 10, 150, v_rows);
EXCEPTION
  WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
END;
/

-- TEST E4: update a non-existing enrollment -> SQL%NOTFOUND -> ORA-20002
DECLARE
  v_rows NUMBER;
BEGIN
  DBMS_OUTPUT.PUT_LINE('=== TEST E4: not enrolled (SQL%NOTFOUND) ===');
  update_score(8, 13, 70, v_rows);
EXCEPTION
  WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
END;
/

-- TEST E5: duplicate student -> DUP_VAL_ON_INDEX -> ORA-20011
DECLARE
  v_rows NUMBER;
BEGIN
  DBMS_OUTPUT.PUT_LINE('=== TEST E5: duplicate student (DUP_VAL_ON_INDEX) ===');
  add_student(1, 'Someone Else', 'someone@auca.ac.rw', v_rows);
EXCEPTION
  WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
END;
/

-- TEST E6: invalid email -> user-defined exception -> ORA-20010
DECLARE
  v_rows NUMBER;
BEGIN
  DBMS_OUTPUT.PUT_LINE('=== TEST E6: invalid email (user-defined exception) ===');
  add_student(20, 'Bad Email', 'not-an-email', v_rows);
EXCEPTION
  WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
END;
/

-- TEST E7: BULK DML ERRORS with SAVE EXCEPTIONS
--   student 6   -> OK (new enrollment)
--   student 999 -> fails: foreign key (student does not exist)
--   student 1   -> fails: unique constraint (already enrolled)
DECLARE
  v_ok  NUMBER;
  v_err NUMBER;
BEGIN
  DBMS_OUTPUT.PUT_LINE('=== TEST E7: bulk DML errors (SAVE EXCEPTIONS) ===');
  bulk_enroll(10, t_id_list(6, 999, 1), v_ok, v_err);
  DBMS_OUTPUT.PUT_LINE('Result -> OK: ' || v_ok || ', failed: ' || v_err);
END;
/

-- TEST E8: empty list -> ORA-20005
DECLARE
  v_ok  NUMBER;
  v_err NUMBER;
BEGIN
  DBMS_OUTPUT.PUT_LINE('=== TEST E8: empty list ===');
  bulk_enroll(10, t_id_list(), v_ok, v_err);
EXCEPTION
  WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
END;
/

-- TEST E9: course does not exist -> explicit cursor %NOTFOUND -> ORA-20009
BEGIN
  DBMS_OUTPUT.PUT_LINE('=== TEST E9: unknown course ===');
  list_course_students(99);
EXCEPTION
  WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
END;
/

-- TEST E10: no scored students in course -> ORA-20004
DECLARE
  v_updated NUMBER;
BEGIN
  DBMS_OUTPUT.PUT_LINE('=== TEST E10: no scores to grade ===');
  compute_course_grades(99, v_updated);
EXCEPTION
  WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
END;
/

-- TEST E11: delete something that does not exist -> SQL%NOTFOUND -> ORA-20012
DECLARE
  v_rows NUMBER;
BEGIN
  DBMS_OUTPUT.PUT_LINE('=== TEST E11: delete non-existing enrollment ===');
  delete_enrollment(8, 13, v_rows);
EXCEPTION
  WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
END;
/

-- TEST E12: invalid score passed to a function called from SQL -> ORA-20003
BEGIN
  DBMS_OUTPUT.PUT_LINE('=== TEST E12: score_to_grade(120) ===');
  DBMS_OUTPUT.PUT_LINE(score_to_grade(120));
EXCEPTION
  WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
END;
/
