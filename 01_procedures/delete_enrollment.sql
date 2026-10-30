-- =============================================================
-- delete_enrollment
-- Removes a student from a course.
-- Concepts: procedure, implicit cursor (DELETE), SQL%ROWCOUNT,
--           SQL%NOTFOUND, RAISE_APPLICATION_ERROR
-- =============================================================
CREATE OR REPLACE PROCEDURE delete_enrollment (
  p_student_id   IN  enrollments.student_id%TYPE,
  p_course_id    IN  enrollments.course_id%TYPE,
  p_rows_deleted OUT NUMBER
)
IS
BEGIN
  DELETE FROM enrollments
   WHERE student_id = p_student_id
     AND course_id  = p_course_id;

  p_rows_deleted := SQL%ROWCOUNT;

  IF SQL%NOTFOUND THEN
    RAISE_APPLICATION_ERROR(-20012, 'Nothing to delete: student ' || p_student_id ||
                                    ' is not enrolled in course ' || p_course_id || '.');
  END IF;

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Enrollment deleted. Rows deleted: ' || p_rows_deleted);
END delete_enrollment;
/
