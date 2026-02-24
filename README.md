# BD Practice

A **training project** for learning database design, backend APIs, and building a simple interactive UI. It simulates a workforce management system including employees, agencies, facilities, shifts, attendance tracking, compliance events, and payroll management.  

## Database

PostgreSQL schema includes:  

- **Agencies** – partner organizations and contracts  
- **Employees** – personal info, employment data, pay rates, and agency links  
- **Facilities** – work locations  
- **Shifts** – scheduled work for facilities  
- **ShiftAssignments** – assign employees to shifts  
- **AttendanceLogs** – track clock-in/out and locations  
- **ComplianceEvents** – record late arrivals, overtime, and other issues  
- **PayrollRecords** – calculate pay with overtime, taxes, and net amounts  

### Automation

- **Stored Procedures**: add employees, assign shifts, calculate payroll, bulk assign, recalc all payroll  
- **Triggers**: log late arrivals, log overtime, prevent shift deletion, mark employees inactive  

This setup allows practicing **relational database concepts, stored procedures, triggers, and automated business logic**.  

## Backend API

The basic API provides endpoints for:  

- Managing employees, shifts, assignments, attendance, and payroll  
- Triggering payroll calculations  
- Reading compliance and attendance logs  

## Streamlit UI

Interactive interface for:  

- Viewing and adding employees  
- Calculating payroll for a selected employee and period  
- Login authentication using environment variables  

Connects directly to the API to visualize and interact with database data.  

## Docker Setup

The project is fully containerized with **Docker Compose**:  

- **PostgreSQL** – the database  
- **API service** – backend server  
- **Streamlit service** – frontend UI  

Run everything with:

```bash
docker compose up --build
