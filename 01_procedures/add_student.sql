-- =============================================================
-- add_student
-- Inserts a new student.
-- Concepts: procedure, IN/OUT parameters, implicit cursor (INSERT),
--           SQL%ROWCOUNT, DUP_VAL_ON_INDEX, user-defined exception
-- =============================================================
CREATE OR REPLACE PROCEDURE add_student (
  p_student_id IN  students.student_id%TYPE,
  p_full_name  IN  students.full_name%TYPE,
  p_email      IN  students.email%TYPE,
  p_rows_added OUT NUMBER
)
IS
  e_invalid_email EXCEPTION;          -- user-defined exception
BEGIN
  IF p_email IS NULL OR INSTR(p_email, '@') = 0 THEN
    RAISE e_invalid_email;
  END IF;

  INSERT INTO students (student_id, full_name, email, status)
  VALUES (p_student_id, p_full_name, p_email, 'ACTIVE');

  p_rows_added := SQL%ROWCOUNT;       -- implicit cursor attribute
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Student added: ' || p_full_name || ' (rows: ' || p_rows_added || ')');
EXCEPTION
  WHEN e_invalid_email THEN
    RAISE_APPLICATION_ERROR(-20010, 'Invalid email address: "' || p_email || '".');
  WHEN DUP_VAL_ON_INDEX THEN
    ROLLBACK;
    RAISE_APPLICATION_ERROR(-20011, 'A student with ID ' || p_student_id ||
                                    ' or email ' || p_email || ' already exists.');
END add_student;
/
