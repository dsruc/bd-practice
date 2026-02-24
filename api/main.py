from fastapi import FastAPI, HTTPException
from sqlalchemy import create_engine
import os
from dotenv import load_dotenv
import pandas as pd

load_dotenv()

DB_USER = os.getenv("DB_USER")
DB_PASS = os.getenv("DB_PASS")
DB_HOST = os.getenv("DB_HOST")
DB_PORT = os.getenv("DB_PORT")
DB_NAME = os.getenv("DB_NAME")

engine = create_engine(f"postgresql://{DB_USER}:{DB_PASS}@{DB_HOST}:{DB_PORT}/{DB_NAME}")

app = FastAPI(title="Company API")


@app.get("/employees")
def get_employees():
    query = "SELECT employee_id, first_name, last_name, position, status FROM employees"
    df = pd.read_sql(query, engine)
    return df.to_dict(orient="records")


@app.post("/employees")
def add_employee(first_name: str, last_name: str, position: str, pay_rate: float):
    insert_query = """
    INSERT INTO employees(first_name,last_name,position,pay_rate,status,employment_date)
    VALUES (%s,%s,%s,%s,'Active',CURRENT_DATE)
    """
    with engine.connect() as conn:
        conn.execute(insert_query, (first_name, last_name, position, pay_rate))
    return {"message": "Сотрудник добавлен"}


@app.post("/payroll/calc")
def calculate_payroll(employee_id: int, start_date: str, end_date: str):
    try:
        with engine.connect() as conn:
            conn.execute("CALL calculate_payroll(%s,%s,%s)", (employee_id, start_date, end_date))
        return {"message": "Зарплата рассчитана"}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
