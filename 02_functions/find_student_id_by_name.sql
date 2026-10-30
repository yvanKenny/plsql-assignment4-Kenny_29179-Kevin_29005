-- =============================================================
-- find_student_id_by_name
-- Returns the ID of the ONE student whose name contains p_name.
-- Concepts: function, SELECT INTO, NO_DATA_FOUND, TOO_MANY_ROWS
-- =============================================================
CREATE OR REPLACE FUNCTION find_student_id_by_name (
  p_name IN VARCHAR2
) RETURN NUMBER
IS
  v_id students.student_id%TYPE;
BEGIN
  SELECT student_id INTO v_id
    FROM students
   WHERE UPPER(full_name) LIKE '%' || UPPER(p_name) || '%';

  RETURN v_id;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20007, 'No student matches "' || p_name || '".');
  WHEN TOO_MANY_ROWS THEN
    RAISE_APPLICATION_ERROR(-20008, 'More than one student matches "' || p_name ||
                                    '". Please give a more specific name.');
END find_student_id_by_name;
/
