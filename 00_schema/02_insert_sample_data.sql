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
