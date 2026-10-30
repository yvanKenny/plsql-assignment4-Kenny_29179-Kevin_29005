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
