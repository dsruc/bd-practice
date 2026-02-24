CREATE OR REPLACE PROCEDURE add_employee_and_assign(
    p_first_name VARCHAR,
    p_last_name VARCHAR,
    p_dob DATE,
    p_position VARCHAR,
    p_pay_rate NUMERIC,
    p_agency_id INT,
    p_shift_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    new_emp_id INT;
BEGIN
    INSERT INTO Employees(first_name,last_name,date_of_birth,
    position,pay_rate,agency_id,status,contact_info,employment_date)
    VALUES (p_first_name, p_last_name, p_dob, p_position, 
    p_pay_rate, p_agency_id,'Active','example@mail.com',CURRENT_DATE)
    RETURNING employee_id INTO new_emp_id;

    INSERT INTO ShiftAssignments(shift_id, employee_id, assigned_at, status)
    VALUES (p_shift_id, new_emp_id, CURRENT_TIMESTAMP,'Assigned');
END;
$$;




CREATE OR REPLACE PROCEDURE calculate_payroll(p_employee_id INT, p_start DATE, p_end DATE)
LANGUAGE plpgsql
AS $$
DECLARE
    total_hours NUMERIC := 0;
    overtime_hours NUMERIC := 0;
    base_rate NUMERIC;
    base_pay NUMERIC;
    overtime_pay NUMERIC;
BEGIN
    SELECT COALESCE(SUM(EXTRACT(EPOCH FROM (clock_out_time - clock_in_time))/3600), 0)
    INTO total_hours
    FROM AttendanceLogs al
    JOIN ShiftAssignments sa ON al.assignment_id = sa.assignment_id
    WHERE sa.employee_id = p_employee_id
      AND al.clock_in_time::date BETWEEN p_start AND p_end;

    SELECT pay_rate INTO base_rate FROM Employees WHERE employee_id = p_employee_id;

    overtime_hours := GREATEST(total_hours - 80, 0);
    base_pay := LEAST(total_hours, 80) * base_rate;
    overtime_pay := overtime_hours * base_rate * 1.5;

    INSERT INTO PayrollRecords(
        employee_id, pay_period_start, pay_period_end,
        total_hours, overtime_hours, base_pay, overtime_pay,
        gross_pay, taxes, net_pay
    )
    VALUES(
        p_employee_id, p_start, p_end,
        total_hours, overtime_hours, base_pay, overtime_pay,
        base_pay + overtime_pay,
        (base_pay + overtime_pay)*0.2,
        (base_pay + overtime_pay)*0.8
    );
END;
$$;




CREATE OR REPLACE FUNCTION log_late_trigger()
RETURNS TRIGGER AS $$
DECLARE
    shift_start TIME;
BEGIN
    SELECT s.start_time
    INTO shift_start
    FROM Shifts s
    JOIN ShiftAssignments sa ON s.shift_id = sa.shift_id
    WHERE sa.assignment_id = NEW.assignment_id
    LIMIT 1;

    IF NEW.clock_in_time::time > shift_start THEN
        INSERT INTO ComplianceEvents(attendance_id, event_type, severity, reported_at)
        VALUES (NEW.attendance_id, 'Опоздание', 'Низкая', CURRENT_TIMESTAMP);
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER attendance_late_trigger
AFTER INSERT ON AttendanceLogs
FOR EACH ROW EXECUTE FUNCTION log_late_trigger();




CREATE OR REPLACE FUNCTION log_overtime_trigger()
RETURNS TRIGGER AS $$
DECLARE
    shift_end TIME;
BEGIN
    SELECT s.end_time
    INTO shift_end
    FROM Shifts s
    JOIN ShiftAssignments sa ON s.shift_id = sa.shift_id
    WHERE sa.assignment_id = NEW.assignment_id
    LIMIT 1;

    IF NEW.clock_out_time::time > shift_end THEN
        INSERT INTO ComplianceEvents(attendance_id, event_type, severity, reported_at)
        VALUES (NEW.attendance_id, 'Сверхурочно', 'Средняя', CURRENT_TIMESTAMP);
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER attendance_overtime_trigger
AFTER INSERT ON AttendanceLogs
FOR EACH ROW EXECUTE FUNCTION log_overtime_trigger();



CREATE OR REPLACE FUNCTION prevent_shift_delete()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM ShiftAssignments WHERE shift_id = OLD.shift_id) THEN
        RAISE EXCEPTION 'Нельзя удалить смену, на которой есть назначенные сотрудники!';
    END IF;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER prevent_shift_delete_trigger
BEFORE DELETE ON Shifts
FOR EACH ROW
EXECUTE FUNCTION prevent_shift_delete();




CREATE OR REPLACE PROCEDURE assign_multiple_employees(p_shift_id INT, p_employee_ids INT[])
LANGUAGE plpgsql
AS $$
DECLARE
    emp_id INT;
BEGIN
    FOREACH emp_id IN ARRAY p_employee_ids
    LOOP
        INSERT INTO ShiftAssignments(shift_id, employee_id, assigned_at, status)
        VALUES (p_shift_id, emp_id, CURRENT_TIMESTAMP,'Assigned');
    END LOOP;
END;
$$;




CREATE OR REPLACE FUNCTION mark_inactive_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.net_pay = 0 THEN
        UPDATE Employees SET status='Inactive' WHERE employee_id = NEW.employee_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER payroll_zero_trigger
AFTER INSERT ON PayrollRecords
FOR EACH ROW
EXECUTE FUNCTION mark_inactive_trigger();




CREATE OR REPLACE PROCEDURE recalc_all_payroll(p_start DATE, p_end DATE)
LANGUAGE plpgsql
AS $$
DECLARE
    emp RECORD;
BEGIN
    FOR emp IN SELECT employee_id FROM Employees LOOP
        CALL calculate_payroll(emp.employee_id, p_start, p_end);
    END LOOP;
END;
$$;
