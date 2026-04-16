import psycopg2
import csv
from datetime import datetime
from dotenv import load_dotenv
import os

# Caminho fixo do .env (Secrets Library)
env_path = r"C:\Users\zeno.filho\projetos\python_secrets_lib\.env"
load_dotenv(dotenv_path=env_path)

# Caminho fixo do CSV
CSV_PATH = r"C:\Users\zeno.filho\Downloads\volume-trafego-praca-pedagio-2024.csv"


def infer_type(value):
    if value == "" or value is None:
        return "TEXT"
    try:
        int(value)
        return "INTEGER"
    except:
        pass
    try:
        float(value.replace(",", "."))
        return "DOUBLE PRECISION"
    except:
        pass
    try:
        datetime.fromisoformat(value)
        return "TIMESTAMP"
    except:
        pass
    return "TEXT"


def infer_schema(csv_path, sample_size=100):
    with open(csv_path, "r", encoding="utf-8") as f:
        reader = csv.reader(f)
        headers = next(reader)

        col_types = ["TEXT"] * len(headers)

        priority = {
            "INTEGER": 1,
            "DOUBLE PRECISION": 2,
            "TIMESTAMP": 3,
            "TEXT": 4
        }

        for i, row in enumerate(reader):
            if i >= sample_size:
                break

            for idx, value in enumerate(row):
                inferred = infer_type(value)
                if priority[inferred] > priority[col_types[idx]]:
                    col_types[idx] = inferred

    return headers, col_types


def create_table(conn, table_name, columns, types):
    cur = conn.cursor()

    cols_sql = ", ".join(
        f'"{col}" {col_type}'
        for col, col_type in zip(columns, types)
    )

    sql = f"""
        CREATE TABLE IF NOT EXISTS {table_name} (
            {cols_sql}
        )
    """

    cur.execute(sql)
    conn.commit()
    cur.close()


def get_db_connection():
    return psycopg2.connect(
        host=os.getenv("DB_HOST"),
        database=os.getenv("DB_NAME"),
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD"),
        port=os.getenv("DB_PORT", 5432)
    )


def copy_csv_to_postgres(csv_path, table_name):
    conn = get_db_connection()

    columns, types = infer_schema(csv_path)
    create_table(conn, table_name, columns, types)

    cur = conn.cursor()

    with open(csv_path, "r", encoding="utf-8") as f:
        cur.copy_expert(
            sql=f"""
                COPY {table_name}
                FROM STDIN
                WITH (
                    FORMAT CSV,
                    HEADER TRUE,
                    DELIMITER ',',
                    ENCODING 'UTF8'
                )
            """,
            file=f
        )

    conn.commit()
    cur.close()
    conn.close()


# EXECUÇÃO
copy_csv_to_postgres(CSV_PATH, "volume_trafego_praca_pedagio_2024")
