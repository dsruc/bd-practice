SELECT e.first_name, e.last_name, p.total_hours
FROM Employees e
JOIN PayrollRecords p ON e.employee_id = p.employee_id
WHERE p.total_hours > (
    SELECT AVG(total_hours) 
    FROM PayrollRecords
);

SELECT s.shift_id, f.name AS facility_name,
       (SELECT COUNT(*) FROM ShiftAssignments sa WHERE sa.shift_id = s.shift_id) AS assigned_count,
       s.required_positions
FROM Shifts s
JOIN Facilities f ON s.facility_id = f.facility_id
WHERE (SELECT COUNT(*) FROM ShiftAssignments sa WHERE sa.shift_id = s.shift_id) > s.required_positions;

SELECT e.first_name, e.last_name, COUNT(c.event_id) AS late_count
FROM Employees e
JOIN ShiftAssignments sa ON e.employee_id = sa.employee_id
JOIN AttendanceLogs al ON sa.assignment_id = al.assignment_id
JOIN ComplianceEvents c ON al.attendance_id = c.attendance_id
WHERE c.event_type = 'Опоздание'
GROUP BY e.employee_id
HAVING COUNT(c.event_id) > (
    SELECT AVG(late_count) FROM (
        SELECT COUNT(c2.event_id) AS late_count
        FROM Employees e2
        JOIN ShiftAssignments sa2 ON e2.employee_id = sa2.employee_id
        JOIN AttendanceLogs al2 ON sa2.assignment_id = al2.assignment_id
        JOIN ComplianceEvents c2 ON al2.attendance_id = c2.attendance_id
        WHERE c2.event_type = 'Опоздание'
        GROUP BY e2.employee_id
    ) AS sub
);

SELECT s.shift_id, f.name AS facility_name, s.shift_date, s.required_positions,
       (s.required_positions - (
           SELECT COUNT(*) FROM ShiftAssignments sa WHERE sa.shift_id = s.shift_id
       )) AS missing_employees
FROM Shifts s
JOIN Facilities f ON s.facility_id = f.facility_id
WHERE (s.required_positions - (
           SELECT COUNT(*) FROM ShiftAssignments sa WHERE sa.shift_id = s.shift_id
       )) > 0;

SELECT e.first_name,
       e.last_name,
       pr.overtime_hours,
       e.agency_id
FROM Employees e
JOIN PayrollRecords pr ON pr.employee_id = e.employee_id
WHERE pr.overtime_hours = (
    SELECT MAX(pr2.overtime_hours)
    FROM PayrollRecords pr2
    JOIN Employees e2 ON pr2.employee_id = e2.employee_id
    WHERE e2.agency_id = e.agency_id
);

SELECT e.first_name, e.last_name
FROM Employees e
WHERE e.employee_id IN (
    SELECT sa.employee_id
    FROM ShiftAssignments sa
    WHERE sa.assignment_id NOT IN (
        SELECT al.assignment_id
        FROM AttendanceLogs al
    )
    GROUP BY sa.employee_id
    HAVING COUNT(sa.assignment_id) > (
        SELECT AVG(missing_count) FROM (
            SELECT COUNT(sa2.assignment_id) AS missing_count
            FROM ShiftAssignments sa2
            LEFT JOIN AttendanceLogs al2 ON sa2.assignment_id = al2.assignment_id
            WHERE al2.attendance_id IS NULL
            GROUP BY sa2.employee_id
        ) AS sub
    )
);

SELECT agency_name, ROUND(AVG(net_pay),2) AS avg_salary
FROM Agencies a
JOIN Employees e ON a.agency_id = e.agency_id
JOIN PayrollRecords p ON e.employee_id = p.employee_id
WHERE a.agency_id IN (
    SELECT agency_id FROM Employees GROUP BY agency_id HAVING COUNT(employee_id) > 1
)
GROUP BY agency_name;

SELECT f.name AS facility_name,
       SUM(p.total_hours) AS total_hours,
       SUM(p.overtime_hours) AS total_overtime
FROM Facilities f
JOIN Shifts s ON f.facility_id = s.facility_id
JOIN ShiftAssignments sa ON s.shift_id = sa.shift_id
JOIN PayrollRecords p ON sa.employee_id = p.employee_id
WHERE f.facility_id IN (
    SELECT facility_id
    FROM Shifts
    GROUP BY facility_id
    HAVING COUNT(shift_id) > 1
)
GROUP BY f.name;

SELECT DISTINCT e.first_name, e.last_name
FROM Employees e
WHERE e.employee_id IN (
    SELECT sa.employee_id
    FROM ShiftAssignments sa
    JOIN AttendanceLogs al ON sa.assignment_id = al.assignment_id
    JOIN ComplianceEvents c ON al.attendance_id = c.attendance_id
    WHERE c.event_type = 'Отсутствие'
);

SELECT a.agency_name, SUM(p.gross_pay) AS total_gross
FROM Agencies a
JOIN Employees e ON a.agency_id = e.agency_id
JOIN PayrollRecords p ON e.employee_id = p.employee_id
WHERE a.agency_id IN (
    SELECT agency_id
    FROM Employees
    GROUP BY agency_id
    HAVING COUNT(employee_id) > 2
)
GROUP BY a.agency_name;

SELECT s.shift_id, s.shift_date, f.name AS facility_name,
       (SELECT STRING_AGG(e.first_name || ' ' || e.last_name, ', ')
        FROM ShiftAssignments sa
        JOIN Employees e ON sa.employee_id = e.employee_id
        WHERE sa.shift_id = s.shift_id
       ) AS assigned_employees
FROM Shifts s
JOIN Facilities f ON s.facility_id = f.facility_id
ORDER BY s.shift_date;

SELECT first_name, last_name, late_count
FROM (
    SELECT e.first_name, e.last_name, COUNT(c.event_id) AS late_count
    FROM Employees e
    JOIN ShiftAssignments sa ON e.employee_id = sa.employee_id
    JOIN AttendanceLogs al ON sa.assignment_id = al.assignment_id
    JOIN ComplianceEvents c ON al.attendance_id = c.attendance_id
    WHERE c.event_type = 'Опоздание'
    GROUP BY e.employee_id
) AS sub
WHERE late_count = (
    SELECT MAX(late_count) FROM (
        SELECT COUNT(c2.event_id) AS late_count
        FROM Employees e2
        JOIN ShiftAssignments sa2 ON e2.employee_id = sa2.employee_id
        JOIN AttendanceLogs al2 ON sa2.assignment_id = al2.assignment_id
        JOIN ComplianceEvents c2 ON al2.attendance_id = c2.attendance_id
        WHERE c2.event_type = 'Опоздание'
        GROUP BY e2.employee_id
    ) AS sub2
);
