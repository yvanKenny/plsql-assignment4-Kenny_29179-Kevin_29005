-- =============================================================
-- compute_course_grades
-- Calculates the letter grade of every scored student in a course
-- and prints how many students got each grade.
-- Concepts: procedure, BULK COLLECT into a nested table of %ROWTYPE
--           records, ASSOCIATIVE ARRAY (INDEX BY VARCHAR2),
--           FORALL bulk UPDATE, collection methods (COUNT, EXISTS,
--           FIRST, NEXT)
-- =============================================================
CREATE OR REPLACE PROCEDURE compute_course_grades (
  p_course_id IN  courses.course_id%TYPE,
  p_updated   OUT NUMBER
)
IS
  TYPE t_enr_tab   IS TABLE OF enrollments%ROWTYPE;              -- nested table of records
  TYPE t_grade_map IS TABLE OF PLS_INTEGER INDEX BY VARCHAR2(1); -- associative array: grade -> count

  v_rows   t_enr_tab;
  v_counts t_grade_map;
  v_grade  VARCHAR2(1);
BEGIN
  -- 1. BULK COLLECT: fetch ALL rows in one call
  SELECT * BULK COLLECT INTO v_rows
    FROM enrollments
   WHERE course_id = p_course_id
     AND score IS NOT NULL;

  IF v_rows.COUNT = 0 THEN
    RAISE_APPLICATION_ERROR(-20004, 'No scored enrollments found for course ' || p_course_id || '.');
  END IF;

  -- 2. Process the collection in memory
  FOR i IN 1 .. v_rows.COUNT LOOP
    v_rows(i).grade := score_to_grade(v_rows(i).score);

    IF v_counts.EXISTS(v_rows(i).grade) THEN
      v_counts(v_rows(i).grade) := v_counts(v_rows(i).grade) + 1;
    ELSE
      v_counts(v_rows(i).grade) := 1;
    END IF;
  END LOOP;

  -- 3. FORALL: write ALL updates in one call
  FORALL i IN 1 .. v_rows.COUNT
    UPDATE enrollments
       SET grade = v_rows(i).grade
     WHERE enrollment_id = v_rows(i).enrollment_id;

  p_updated := SQL%ROWCOUNT;
  COMMIT;

  -- 4. Print the grade distribution by walking the associative array
  DBMS_OUTPUT.PUT_LINE('Grades computed for course ' || p_course_id ||
                       '. Rows updated: ' || p_updated);
  v_grade := v_counts.FIRST;
  WHILE v_grade IS NOT NULL LOOP
    DBMS_OUTPUT.PUT_LINE('  Grade ' || v_grade || ': ' || v_counts(v_grade) || ' student(s)');
    v_grade := v_counts.NEXT(v_grade);
  END LOOP;
END compute_course_grades;
/
