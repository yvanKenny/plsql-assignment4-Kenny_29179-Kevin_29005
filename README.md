# PL/SQL Assignment IV – Student Registration \& Grading System

**Course:** Database Development with PL/SQL (INSY 8311)
**Instructor:** Eric Maniraguha

## Group Members

|Full Name|Student ID|
|-|-|
|*Ruhumuriza Yvan Kenny*|*29179*|
|Bizimana Kevin|*29005*|

## Application Description

A small university system that:

* registers **students** and **courses**,
* **enrolls** students in courses (one at a time or many at once),
* records **scores** and computes **letter grades** (A–F),
* prints a **transcript** for a student and a **class list** for a course.

### Requirements of the application

1. A student cannot be enrolled twice in the same course.
2. A score must be between 0 and 100.
3. Grades: A ≥ 80, B ≥ 70, C ≥ 60, D ≥ 50, F < 50.
4. Errors (unknown student, unknown course, invalid score, duplicates) must give a clear message.
5. Enrolling many students at once must be fast and must not stop because of one bad row.

## Database Schema

```
STUDENTS (student\_id PK, full\_name, email UNIQUE, status CHECK)
    │ 1
    │
    │ N
ENROLLMENTS (enrollment\_id PK, student\_id FK, course\_id FK, score CHECK 0-100, grade CHECK A-F,
             UNIQUE(student\_id, course\_id))
    │ N
    │
    │ 1
COURSES (course\_id PK, course\_code UNIQUE, title, credits CHECK 1-6)
```

`ENROLLMENTS` links students and courses (a many-to-many relationship).
`T\_ID\_LIST` is a schema-level nested table type used to pass a list of student IDs.

## How to Run

Run the scripts **in this order** (SQL Developer, SQL\*Plus, or Oracle Live SQL):

1. `00\_schema/01\_create\_tables.sql`
2. `00\_schema/02\_insert\_sample\_data.sql`
3. All files in `02\_functions/` (**functions first**, because the procedures call them)
4. All files in `01\_procedures/`
5. `03\_tests/test\_success\_cases.sql`
6. `03\_tests/test\_error\_cases.sql`

> Note: we compile functions before procedures because procedures such as
> `print\_transcript` and `bulk\_enroll` call functions. Compiling a procedure first
> would leave it INVALID until the function exists.

## Where Each Concept Is Used

|Requirement|File(s)|
|-|-|
|User-defined record (`TYPE ... IS RECORD`)|`print\_transcript.sql`|
|`%ROWTYPE` record|`get\_student\_average.sql`, `count\_students\_in\_course.sql`, `compute\_course\_grades.sql`|
|Nested table collection|`t\_id\_list` (schema), `bulk\_enroll.sql`, `compute\_course\_grades.sql`|
|Associative array (`INDEX BY`)|`compute\_course\_grades.sql`|
|Implicit cursor – INSERT / UPDATE / DELETE|`add\_student.sql`, `update\_score.sql`, `delete\_enrollment.sql`|
|`SQL%ROWCOUNT`, `SQL%FOUND`, `SQL%NOTFOUND`|`update\_score.sql`, `delete\_enrollment.sql`, `add\_student.sql`|
|Explicit cursor OPEN / FETCH / CLOSE|`print\_transcript.sql`, `count\_students\_in\_course.sql`|
|Cursor FOR loop (with parameter)|`list\_course\_students.sql`|
|`BULK COLLECT`|`compute\_course\_grades.sql`|
|`FORALL` (INSERT and UPDATE)|`bulk\_enroll.sql`, `compute\_course\_grades.sql`|
|`SAVE EXCEPTIONS` + `SQL%BULK\_EXCEPTIONS`|`bulk\_enroll.sql`|
|`NO\_DATA\_FOUND`|`get\_student\_average.sql`, `find\_student\_id\_by\_name.sql`|
|`TOO\_MANY\_ROWS`|`find\_student\_id\_by\_name.sql`|
|`DUP\_VAL\_ON\_INDEX`|`add\_student.sql`|
|User-defined exception|`update\_score.sql` (`e\_invalid\_score`), `add\_student.sql` (`e\_invalid\_email`), `bulk\_enroll.sql` (`e\_bulk\_errors`)|
|`RAISE\_APPLICATION\_ERROR`|all procedures and functions|
|Function called from SQL|`test\_success\_cases.sql` – TEST S8|

## Error Codes

|Code|Meaning|
|-|-|
|-20001|Student does not exist|
|-20002|Student not enrolled in the course (update)|
|-20003|Score not between 0 and 100|
|-20004|No scored enrollments to grade|
|-20005|Empty list of students|
|-20006|Score is NULL|
|-20007|No student matches the name|
|-20008|More than one student matches the name|
|-20009|Course does not exist|
|-20010|Invalid email|
|-20011|Duplicate student ID or email|
|-20012|Nothing to delete|

## Screenshots

See the `screenshots/` folder – one screenshot per test case (success and error).

## Use of AI

We used Claude (an AI assistant by Anthropic) to help us understand the assignment,
explain the PL/SQL concepts, and generate a first version of the code. We then ran
every script ourselves, checked the results, and made sure both members can
explain every line.

