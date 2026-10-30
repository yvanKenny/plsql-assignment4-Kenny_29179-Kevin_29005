# Implementation Notes

## 1. Overall design

- **Tables:** `STUDENTS`, `COURSES`, `ENROLLMENTS` (link table).
- **Functions** (return a value): `score_to_grade`, `get_student_average`,
  `find_student_id_by_name`, `count_students_in_course`.
- **Procedures** (perform an action): `add_student`, `update_score`,
  `delete_enrollment`, `print_transcript`, `list_course_students`,
  `bulk_enroll`, `compute_course_grades`.

Procedures reuse functions (for example `print_transcript` calls
`get_student_average`), so validation logic is written once.

## 2. Records

- **User-defined record** (`t_result` in `print_transcript`): groups the course code,
  title, score and grade of one transcript line into one variable.
- **`%ROWTYPE`** (`students%ROWTYPE`, `enrollments%ROWTYPE`, `c_course%ROWTYPE`): the
  record automatically has the same columns as the table/cursor, so if the table
  changes the code adapts.

## 3. Collections

- **Nested table** `t_id_list` (schema level): lets a caller pass a whole list of
  student IDs into `bulk_enroll`, e.g. `t_id_list(3, 4, 5)`.
- **Nested table of records** `t_enr_tab` in `compute_course_grades`: holds all
  enrollments of a course in memory.
- **Associative array** `t_grade_map` (`INDEX BY VARCHAR2(1)`): counts how many students
  got each grade, using the grade letter as the key. Walked with `FIRST` / `NEXT`.

## 4. Cursors

- **Implicit cursors:** every `INSERT`, `UPDATE`, `DELETE` uses one. We check
  `SQL%ROWCOUNT` (how many rows), `SQL%FOUND` / `SQL%NOTFOUND` (did it affect any row).
  For example, `update_score` raises `-20002` when `SQL%NOTFOUND` is true, because
  an UPDATE that changes 0 rows is **not** an Oracle error and would otherwise go unnoticed.
- **Explicit cursors:** `print_transcript` uses `OPEN / FETCH / CLOSE` with
  `%NOTFOUND`, `%ROWCOUNT` and `%ISOPEN`. `list_course_students` uses a
  **parameterized cursor FOR loop**, which opens, fetches and closes automatically.

## 5. Bulk processing and performance

PL/SQL code runs in the **PL/SQL engine**, while SQL statements run in the **SQL engine**.
Every time PL/SQL sends a SQL statement to the SQL engine there is a **context switch**,
which has a cost.

| Approach | Context switches for 10,000 rows |
|---|---|
| Row-by-row loop (`FOR ... LOOP INSERT ... END LOOP`) | ~10,000 |
| `FORALL` | 1 |
| Cursor loop fetching one row at a time | ~10,000 |
| `BULK COLLECT` | 1 |

So bulk processing is usually **much faster** for large numbers of rows.

- **`BULK COLLECT`** (`compute_course_grades`): fetches all rows of a course into a
  collection in one step.
- **`FORALL`** (`bulk_enroll`, `compute_course_grades`): sends all INSERTs/UPDATEs
  to the SQL engine in one step.
- **Memory:** `BULK COLLECT` loads everything into memory. For very large tables we would
  use an explicit cursor with `FETCH ... BULK COLLECT INTO ... LIMIT 500` inside a loop,
  processing the data in batches. Our tables are small, so a single fetch is fine.

### Bulk DML error handling (`SAVE EXCEPTIONS`)

Without `SAVE EXCEPTIONS`, the first failing row stops the whole `FORALL` statement.
With `SAVE EXCEPTIONS`, Oracle continues with the other rows and, at the end, raises
**ORA-24381**. We map it to our exception `e_bulk_errors` with `PRAGMA EXCEPTION_INIT`, then
loop over `SQL%BULK_EXCEPTIONS` to print **which** row failed (`ERROR_INDEX`) and **why**
(`ERROR_CODE`).

Example (test E7): `bulk_enroll(10, t_id_list(6, 999, 1))`

- student 6 → inserted
- student 999 → fails (foreign key: student does not exist)
- student 1 → fails (unique constraint: already enrolled)

**Design decision:** we `COMMIT` the successful rows and report the failed ones, so the
registrar only has to fix the bad entries. (An alternative would be to `ROLLBACK`
everything if any row fails.)

## 6. Exception handling

- **Predefined:** `NO_DATA_FOUND`, `TOO_MANY_ROWS`, `DUP_VAL_ON_INDEX`.
- **User-defined:** `e_invalid_score`, `e_invalid_email`, `e_bulk_errors`.
- **`RAISE_APPLICATION_ERROR`** with our own codes (-20001 to -20012) and clear messages
  (see README).
- **No silent errors:** `WHEN OTHERS` is only used to close an open cursor and then
  `RAISE` again, so the real error is never hidden. Functions never return a fake
  value (like 0) when something is wrong. They raise an error instead.

## 7. Testing

- `03_tests/test_success_cases.sql`: 9 tests of normal use.
- `03_tests/test_error_cases.sql`: 12 tests, each one triggers a specific error and
  prints it, proving that every exception path works.
