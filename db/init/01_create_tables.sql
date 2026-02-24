CREATE TABLE Agencies (
    agency_id SERIAL PRIMARY KEY,
    agency_name VARCHAR(255) NOT NULL,
    contact_info VARCHAR(255),
    contract_terms TEXT
);

CREATE TABLE Employees (
    employee_id SERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    date_of_birth DATE,
    employment_date DATE,
    position VARCHAR(100),
    status VARCHAR(50),
    contact_info VARCHAR(255),
    pay_rate NUMERIC(10,2),
    agency_id INT,
    CONSTRAINT fk_employee_agency FOREIGN KEY (agency_id)
        REFERENCES Agencies(agency_id)
        ON UPDATE CASCADE ON DELETE SET NULL
);

CREATE TABLE Facilities (
    facility_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    location VARCHAR(255),
    type VARCHAR(100)
);

CREATE TABLE Shifts (
    shift_id SERIAL PRIMARY KEY,
    facility_id INT,
    shift_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    required_positions INT,
    notes TEXT,
    CONSTRAINT fk_shift_facility FOREIGN KEY (facility_id)
        REFERENCES Facilities(facility_id)
        ON UPDATE CASCADE ON DELETE SET NULL
);

CREATE TABLE ShiftAssignments (
    assignment_id SERIAL PRIMARY KEY,
    shift_id INT NOT NULL,
    employee_id INT NOT NULL,
    assigned_at TIMESTAMP,
    status VARCHAR(50),
    CONSTRAINT fk_assignment_shift FOREIGN KEY (shift_id)
        REFERENCES Shifts(shift_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_assignment_employee FOREIGN KEY (employee_id)
        REFERENCES Employees(employee_id)
        ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE AttendanceLogs (
    attendance_id SERIAL PRIMARY KEY,
    assignment_id INT NOT NULL,
    clock_in_time TIMESTAMP,
    clock_out_time TIMESTAMP,
    location_checked BOOLEAN,
    status VARCHAR(50),
    CONSTRAINT fk_attendance_assignment FOREIGN KEY (assignment_id)
        REFERENCES ShiftAssignments(assignment_id)
        ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE ComplianceEvents (
    event_id SERIAL PRIMARY KEY,
    attendance_id INT NOT NULL,
    event_type VARCHAR(100),
    severity VARCHAR(50),
    reported_at TIMESTAMP,
    CONSTRAINT fk_compliance_attendance FOREIGN KEY (attendance_id)
        REFERENCES AttendanceLogs(attendance_id)
        ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE PayrollRecords (
    payroll_id SERIAL PRIMARY KEY,
    employee_id INT NOT NULL,
    pay_period_start DATE,
    pay_period_end DATE,
    total_hours NUMERIC(10,2),
    overtime_hours NUMERIC(10,2),
    base_pay NUMERIC(10,2),
    overtime_pay NUMERIC(10,2),
    gross_pay NUMERIC(10,2),
    taxes NUMERIC(10,2),
    net_pay NUMERIC(10,2),
    CONSTRAINT fk_payroll_employee FOREIGN KEY (employee_id)
        REFERENCES Employees(employee_id)
        ON UPDATE CASCADE ON DELETE CASCADE
);