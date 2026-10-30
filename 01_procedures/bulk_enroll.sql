-- =============================================================
-- bulk_enroll
-- Enrolls a LIST of students into one course in a single operation.
-- Concepts: procedure, nested table collection as a parameter,
--           FORALL ... SAVE EXCEPTIONS (bulk INSERT),
--           SQL%BULK_EXCEPTIONS (bulk DML error handling),
--           PRAGMA EXCEPTION_INIT
-- =============================================================
CREATE OR REPLACE PROCEDURE bulk_enroll (
  p_course_id   IN  courses.course_id%TYPE,
  p_student_ids IN  t_id_list,          -- nested table (created in 01_create_tables.sql)
  p_ok_count    OUT NUMBER,
  p_err_count   OUT NUMBER
)
IS
  e_bulk_errors EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_bulk_errors, -24381);   -- ORA-24381: error(s) in array DML
  v_dummy NUMBER;
BEGIN
  p_ok_count  := 0;
  p_err_count := 0;

  IF p_student_ids IS NULL OR p_student_ids.COUNT = 0 THEN
    RAISE_APPLICATION_ERROR(-20005, 'The list of students is empty.');
  END IF;

  -- Raises ORA-20009 if the course does not exist
  v_dummy := count_students_in_course(p_course_id);

  -- ONE call to the SQL engine for the whole list
  FORALL i IN 1 .. p_student_ids.COUNT SAVE EXCEPTIONS
    INSERT INTO enrollments (student_id, course_id)
    VALUES (p_student_ids(i), p_course_id);

  p_ok_count := SQL%ROWCOUNT;
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Bulk enroll finished: ' || p_ok_count || ' student(s) enrolled.');
EXCEPTION
  WHEN e_bulk_errors THEN
    -- Some rows failed; the others were inserted successfully.
    p_err_count := SQL%BULK_EXCEPTIONS.COUNT;
    p_ok_count  := p_student_ids.COUNT - p_err_count;
    FOR j IN 1 .. p_err_count LOOP
      DBMS_OUTPUT.PUT_LINE('  Student ' ||
        p_student_ids(SQL%BULK_EXCEPTIONS(j).ERROR_INDEX) || ' failed: ' ||
        SQLERRM(-SQL%BULK_EXCEPTIONS(j).ERROR_CODE));
    END LOOP;
    COMMIT;   -- keep the successful rows (design decision, see IMPLEMENTATION_NOTES.md)
    DBMS_OUTPUT.PUT_LINE('Bulk enroll finished: ' || p_ok_count || ' ok, ' ||
                         p_err_count || ' failed.');
END bulk_enroll;
/
