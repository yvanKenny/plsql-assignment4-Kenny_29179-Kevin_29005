-- =============================================================
-- print_transcript
-- Prints all courses, scores and grades of one student.
-- Concepts: procedure, USER-DEFINED RECORD, explicit cursor with
--           OPEN / FETCH / CLOSE, cursor attributes, calling a function
-- =============================================================
CREATE OR REPLACE PROCEDURE print_transcript (
  p_student_id IN students.student_id%TYPE
)
IS
  -- User-defined record type: one line of the transcript
  TYPE t_result IS RECORD (
    course_code courses.course_code%TYPE,
    title       courses.title%TYPE,
    score       enrollments.score%TYPE,
    grade       enrollments.grade%TYPE
  );
  v_row t_result;

  -- Explicit cursor
  CURSOR c_results IS
    SELECT c.course_code, c.title, e.score, e.grade
      FROM enrollments e
      JOIN courses c ON c.course_id = e.course_id
     WHERE e.student_id = p_student_id
     ORDER BY c.course_code;

  v_avg NUMBER;
BEGIN
  -- Raises ORA-20001 if the student does not exist
  v_avg := get_student_average(p_student_id);

  DBMS_OUTPUT.PUT_LINE('Transcript for student ' || p_student_id);
  DBMS_OUTPUT.PUT_LINE(RPAD('CODE', 10) || RPAD('TITLE', 35) || RPAD('SCORE', 7) || 'GRADE');
  DBMS_OUTPUT.PUT_LINE(RPAD('-', 57, '-'));

  OPEN c_results;
  LOOP
    FETCH c_results INTO v_row;
    EXIT WHEN c_results%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE(RPAD(v_row.course_code, 10) ||
                         RPAD(v_row.title, 35) ||
                         RPAD(NVL(TO_CHAR(v_row.score), '-'), 7) ||
                         NVL(v_row.grade, '-'));
  END LOOP;

  IF c_results%ROWCOUNT = 0 THEN
    DBMS_OUTPUT.PUT_LINE('(No courses yet)');
  END IF;
  CLOSE c_results;

  DBMS_OUTPUT.PUT_LINE('Average score: ' || NVL(TO_CHAR(v_avg), 'N/A'));
EXCEPTION
  WHEN OTHERS THEN
    IF c_results%ISOPEN THEN CLOSE c_results; END IF;
    RAISE;   -- re-raise: the caller sees the real error
END print_transcript;
/
