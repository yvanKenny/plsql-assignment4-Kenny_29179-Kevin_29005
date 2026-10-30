-- RUN_ALL_SETUP.sql : tables + sample data + functions + procedures in one file
-- Paste everything into FreeSQL and click RUN SCRIPT.


-- ===== FILE: 00_schema/01_create_tables.sql =====
-- =============================================================
-- 01_create_tables.sql
-- Student Registration & Grading System
-- Creates the tables, relationships (foreign keys) and constraints.
-- =============================================================

-- Drop old objects first, so this script can be run again safely.
BEGIN
  FOR obj IN (SELECT 'DROP TABLE enrollments CASCADE CONSTRAINTS' AS cmd FROM dual
              UNION ALL SELECT 'DROP TABLE courses CASCADE CONSTRAINTS' FROM dual
              UNION ALL SELECT 'DROP TABLE students CASCADE CONSTRAINTS' FROM dual
              UNION ALL SELECT 'DROP TYPE t_id_list FORCE' FROM dual) LOOP
    BEGIN
      EXECUTE IMMEDIATE obj.cmd;
    EXCEPTION
      WHEN OTHERS THEN
        -- ORA-00942 = table does not exist, ORA-04043 = type does not exist
        IF SQLCODE NOT IN (-942, -4043) THEN RAISE; END IF;
    END;
  END LOOP;
END;
/

-- 1. STUDENTS: one row per student
CREATE TABLE students (
  student_id  NUMBER        CONSTRAINT pk_students PRIMARY KEY,
  full_name   VARCHAR2(100) CONSTRAINT nn_students_name NOT NULL,
  email       VARCHAR2(100) CONSTRAINT nn_students_email NOT NULL
                            CONSTRAINT uq_students_email UNIQUE,
  status      VARCHAR2(10)  DEFAULT 'ACTIVE'
                            CONSTRAINT ck_students_status CHECK (status IN ('ACTIVE', 'INACTIVE'))
);

-- 2. COURSES: one row per course
CREATE TABLE courses (
  course_id   NUMBER        CONSTRAINT pk_courses PRIMARY KEY,
  course_code VARCHAR2(10)  CONSTRAINT nn_courses_code NOT NULL
                            CONSTRAINT uq_courses_code UNIQUE,
  title       VARCHAR2(100) CONSTRAINT nn_courses_title NOT NULL,
  credits     NUMBER(1)     CONSTRAINT ck_courses_credits CHECK (credits BETWEEN 1 AND 6)
);

-- 3. ENROLLMENTS: links a student to a course (many-to-many), holds score and grade
CREATE TABLE enrollments (
  enrollment_id NUMBER GENERATED ALWAYS AS IDENTITY CONSTRAINT pk_enrollments PRIMARY KEY,
  student_id    NUMBER       CONSTRAINT nn_enr_student NOT NULL
                             CONSTRAINT fk_enr_student REFERENCES students(student_id),
  course_id     NUMBER       CONSTRAINT nn_enr_course NOT NULL
                             CONSTRAINT fk_enr_course REFERENCES courses(course_id),
  score         NUMBER(5,2)  CONSTRAINT ck_enr_score CHECK (score BETWEEN 0 AND 100),
  grade         CHAR(1)      CONSTRAINT ck_enr_grade CHECK (grade IN ('A','B','C','D','F')),
  CONSTRAINT uq_enr_student_course UNIQUE (student_id, course_id)  -- no double enrollment
);

-- 4. A schema-level collection type (nested table of numbers).
--    It lets us pass a LIST of student IDs into a procedure (see bulk_enroll).
CREATE OR REPLACE TYPE t_id_list AS TABLE OF NUMBER;
/

-- ===== FILE: 00_schema/02_insert_sample_data.sql =====
-- =============================================================
-- 02_insert_sample_data.sql
-- Sample data for the Student Registration & Grading System
-- =============================================================

-- Students (note: two students contain the name "Alice" -> used to test TOO_MANY_ROWS)
INSERT INTO students (student_id, full_name, email, status) VALUES (1, 'Alice Uwase',       'alice.uwase@auca.ac.rw',   'ACTIVE');
INSERT INTO students (student_id, full_name, email, status) VALUES (2, 'Alice Mukamana',    'alice.mukamana@auca.ac.rw','ACTIVE');
INSERT INTO students (student_id, full_name, email, status) VALUES (3, 'Jean Habimana',     'jean.habimana@auca.ac.rw', 'ACTIVE');
INSERT INTO students (student_id, full_name, email, status) VALUES (4, 'Grace Ingabire',    'grace.ingabire@auca.ac.rw','ACTIVE');
INSERT INTO students (student_id, full_name, email, status) VALUES (5, 'Eric Niyonzima',    'eric.niyonzima@auca.ac.rw','ACTIVE');
INSERT INTO students (student_id, full_name, email, status) VALUES (6, 'Diane Uwimana',     'diane.uwimana@auca.ac.rw', 'ACTIVE');
INSERT INTO students (student_id, full_name, email, status) VALUES (7, 'Patrick Mugisha',   'patrick.mugisha@auca.ac.rw','ACTIVE');
INSERT INTO students (student_id, full_name, email, status) VALUES (8, 'Claudine Iradukunda','claudine.ira@auca.ac.rw', 'INACTIVE');

-- Courses
INSERT INTO courses (course_id, course_code, title, credits) VALUES (10, 'INSY8311', 'Database Development with PL/SQL', 4);
INSERT INTO courses (course_id, course_code, title, credits) VALUES (11, 'INSY8312', 'Web Technologies',                 3);
INSERT INTO courses (course_id, course_code, title, credits) VALUES (12, 'INSY8313', 'Software Engineering',             4);
INSERT INTO courses (course_id, course_code, title, credits) VALUES (13, 'INSY8314', 'Computer Networks',                3);

-- Enrollments (grade is left empty; the procedure compute_course_grades fills it in)
INSERT INTO enrollments (student_id, course_id, score) VALUES (1, 10, 85);
INSERT INTO enrollments (student_id, course_id, score) VALUES (1, 11, 72);
INSERT INTO enrollments (student_id, course_id, score) VALUES (1, 12, 66);
INSERT INTO enrollments (student_id, course_id, score) VALUES (2, 10, 64);
INSERT INTO enrollments (student_id, course_id, score) VALUES (2, 12, 48);
INSERT INTO enrollments (student_id, course_id, score) VALUES (3, 11, 91);
INSERT INTO enrollments (student_id, course_id, score) VALUES (4, 12, NULL);
INSERT INTO enrollments (student_id, course_id, score) VALUES (5, 13, 77);
INSERT INTO enrollments (student_id, course_id, score) VALUES (6, 11, 55);
INSERT INTO enrollments (student_id, course_id, score) VALUES (7, 10, 59);

COMMIT;

-- Quick check
SELECT 'students' AS table_name, COUNT(*) AS row_count FROM students
UNION ALL SELECT 'courses', COUNT(*) FROM courses
UNION ALL SELECT 'enrollments', COUNT(*) FROM enrollments;

-- ===== FILE: 02_functions/count_students_in_course.sql =====
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

-- ===== FILE: 02_functions/find_student_id_by_name.sql =====
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

-- ===== FILE: 02_functions/get_student_average.sql =====
-- =============================================================
-- get_student_average
-- Returns the average score of a student (NULL if no scores yet).
-- Concepts: function, %ROWTYPE record, %TYPE, NO_DATA_FOUND,
--           RAISE_APPLICATION_ERROR
-- =============================================================
CREATE OR REPLACE FUNCTION get_student_average (
  p_student_id IN students.student_id%TYPE
) RETURN NUMBER
IS
  v_student students%ROWTYPE;   -- record with the same columns as the STUDENTS table
  v_avg     NUMBER;
BEGIN
  -- 1. Make sure the student exists (raises NO_DATA_FOUND if not)
  SELECT * INTO v_student
    FROM students
   WHERE student_id = p_student_id;

  -- 2. Compute the average (AVG ignores NULL scores)
  SELECT AVG(score) INTO v_avg
    FROM enrollments
   WHERE student_id = p_student_id;

  -- NULL means "no scores yet" - we do NOT return 0, because 0 would be misleading.
  RETURN ROUND(v_avg, 2);
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20001, 'Student ' || p_student_id || ' does not exist.');
END get_student_average;
/

-- ===== FILE: 02_functions/score_to_grade.sql =====
-- =============================================================
-- score_to_grade
-- Converts a numeric score (0-100) into a letter grade.
-- Can be called from SQL:  SELECT score_to_grade(85) FROM dual;
-- Concepts: function, IN parameter, RAISE_APPLICATION_ERROR
-- =============================================================
CREATE OR REPLACE FUNCTION score_to_grade (
  p_score IN NUMBER
) RETURN VARCHAR2
IS
BEGIN
  IF p_score IS NULL THEN
    RAISE_APPLICATION_ERROR(-20006, 'Score is NULL - cannot compute a grade.');
  ELSIF p_score < 0 OR p_score > 100 THEN
    RAISE_APPLICATION_ERROR(-20003, 'Score must be between 0 and 100. Given: ' || p_score);
  ELSIF p_score >= 80 THEN RETURN 'A';
  ELSIF p_score >= 70 THEN RETURN 'B';
  ELSIF p_score >= 60 THEN RETURN 'C';
  ELSIF p_score >= 50 THEN RETURN 'D';
  ELSE RETURN 'F';
  END IF;
END score_to_grade;
/

-- ===== FILE: 01_procedures/add_student.sql =====
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

-- ===== FILE: 01_procedures/bulk_enroll.sql =====
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

-- ===== FILE: 01_procedures/compute_course_grades.sql =====
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

-- ===== FILE: 01_procedures/delete_enrollment.sql =====
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

-- ===== FILE: 01_procedures/list_course_students.sql =====
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

-- ===== FILE: 01_procedures/print_transcript.sql =====
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

-- ===== FILE: 01_procedures/update_score.sql =====
-- =============================================================
-- update_score
-- Updates the score (and grade) of a student in a course.
-- Concepts: procedure, IN/OUT parameters, implicit cursor (UPDATE),
--           SQL%ROWCOUNT, SQL%FOUND, SQL%NOTFOUND,
--           user-defined exception, RAISE_APPLICATION_ERROR
-- =============================================================
CREATE OR REPLACE PROCEDURE update_score (
  p_student_id   IN  enrollments.student_id%TYPE,
  p_course_id    IN  enrollments.course_id%TYPE,
  p_score        IN  enrollments.score%TYPE,
  p_rows_updated OUT NUMBER
)
IS
  e_invalid_score EXCEPTION;          -- user-defined exception
BEGIN
  IF p_score IS NULL OR p_score < 0 OR p_score > 100 THEN
    RAISE e_invalid_score;
  END IF;

  UPDATE enrollments
     SET score = p_score,
         grade = score_to_grade(p_score)
   WHERE student_id = p_student_id
     AND course_id  = p_course_id;

  p_rows_updated := SQL%ROWCOUNT;

  IF SQL%NOTFOUND THEN
    RAISE_APPLICATION_ERROR(-20002, 'Student ' || p_student_id ||
                                    ' is not enrolled in course ' || p_course_id || '.');
  ELSIF SQL%FOUND THEN
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Score updated to ' || p_score || '. Rows updated: ' || p_rows_updated);
  END IF;
EXCEPTION
  WHEN e_invalid_score THEN
    RAISE_APPLICATION_ERROR(-20003, 'Score must be between 0 and 100. Given: ' ||
                                    NVL(TO_CHAR(p_score), 'NULL'));
END update_score;
/
