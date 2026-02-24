import streamlit as st
import pandas as pd
import requests
from dotenv import load_dotenv
import os
import bcrypt

load_dotenv()

API_URL = os.getenv("API_URL", "http://api:8000")


def check_login(username, password):
    if username == os.getenv("STREAMLIT_USER") and password == os.getenv("STREAMLIT_PASSWORD"):
        return True
    return False


if 'logged_in' not in st.session_state:
    st.session_state.logged_in = False

if not st.session_state.logged_in:
    st.title("Вход в систему")
    username = st.text_input("Имя пользователя")
    password = st.text_input("Пароль", type="password")
    if st.button("Войти"):
        if check_login(username, password):
            st.session_state.logged_in = True
            st.success("Вы успешно вошли!")
        else:
            st.error("Неверное имя пользователя или пароль")
else:
    st.sidebar.title("Навигация")
    menu = st.sidebar.radio("Раздел", ["Сотрудники", "Зарплата"])


    if menu == "Сотрудники":
        st.header("Сотрудники")
        try:
            r = requests.get(f"{API_URL}/employees")
            r.raise_for_status()
            df = pd.DataFrame(r.json())
            st.dataframe(df)
        except Exception as e:
            st.error(f"Ошибка получения данных: {e}")

        st.subheader("Добавить сотрудника")
        first_name = st.text_input("Имя")
        last_name = st.text_input("Фамилия")
        position = st.text_input("Должность")
        pay_rate = st.number_input("Ставка оплаты", min_value=0.0, step=0.1)
        if st.button("Добавить"):
            try:
                r = requests.post(f"{API_URL}/employees", params={
                    "first_name": first_name,
                    "last_name": last_name,
                    "position": position,
                    "pay_rate": pay_rate
                })
                r.raise_for_status()
                st.success("Сотрудник добавлен!")
            except Exception as e:
                st.error(f"Ошибка: {e}")


    elif menu == "Зарплата":
        st.header("Расчёт зарплаты")
        employee_id = st.number_input("ID сотрудника", min_value=1, step=1)
        start_date = st.date_input("Дата начала периода")
        end_date = st.date_input("Дата конца периода")
        if st.button("Рассчитать"):
            try:
                r = requests.post(f"{API_URL}/payroll/calc", params={
                    "employee_id": employee_id,
                    "start_date": str(start_date),
                    "end_date": str(end_date)
                })
                r.raise_for_status()
                st.success("Зарплата рассчитана!")
            except Exception as e:
                st.error(f"Ошибка: {e}")