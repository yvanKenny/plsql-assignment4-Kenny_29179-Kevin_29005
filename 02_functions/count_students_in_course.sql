-- =============================================================
-- count_students_in_course
-- Returns how many students are enrolled in a course.
-- Concepts: function, explicit cursor with OPEN / FETCH / CLOSE,
--           %ROWTYPE record, NO_DATA_FOUND
-- =============================================================
CREATE OR REPLACE FUNCTION count_students_in_course (
  p_course_id IN courses.course_id%TYPE
) RETURN NUMBER
IS
  CURSOR c_course IS
    SELECT * FROM courses WHERE course_id = p_course_id;
  v_course c_course%ROWTYPE;     -- record based on the cursor
  v_count  NUMBER;
BEGIN
  OPEN c_course;
  FETCH c_course INTO v_course;
  IF c_course%NOTFOUND THEN
    CLOSE c_course;
    RAISE_APPLICATION_ERROR(-20009, 'Course ' || p_course_id || ' does not exist.');
  END IF;
  CLOSE c_course;

  SELECT COUNT(*) INTO v_count
    FROM enrollments
   WHERE course_id = p_course_id;

  RETURN v_count;
EXCEPTION
  WHEN OTHERS THEN
    IF c_course%ISOPEN THEN CLOSE c_course; END IF;
    RAISE;   -- re-raise: never hide unexpected errors
END count_students_in_course;
/
