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
