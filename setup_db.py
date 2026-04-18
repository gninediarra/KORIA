"""
Run this ONCE to create the PostgreSQL database and user.
Usage: python setup_db.py
"""
import glob
import getpass
import os
import subprocess
import sys

DB_NAME = "gabeseye"
DB_USER = "gabeseye_user"
DB_PASS = "gabeseye2024"

candidates = sorted(
    glob.glob("C:/Program Files/PostgreSQL/*/bin/psql.exe")
    + glob.glob("D:/PostgreSQL/bin/psql.exe")
    + glob.glob("D:/PostgreSQL/*/bin/psql.exe")
)
PSQL = candidates[-1] if candidates else "psql"

print("=== GabèsEye — PostgreSQL setup ===")
print(f"psql: {PSQL}")
pg_password = getpass.getpass("Mot de passe du superuser PostgreSQL (postgres): ")


def psql(sql: str, dbname: str = "postgres") -> bool:
    env = os.environ.copy()
    env["PGPASSWORD"] = pg_password
    env["PGCLIENTENCODING"] = "UTF8"
    result = subprocess.run(
        [PSQL, "-h", "localhost", "-p", "5432", "-U", "postgres", "-d", dbname],
        input=sql.encode("utf-8"),
        env=env,
        capture_output=True,
    )
    out = (result.stdout + result.stderr).decode("utf-8", errors="replace").strip()
    if out:
        print(out)
    return result.returncode == 0


# Step 1 — create user
if not psql(f"""
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '{DB_USER}') THEN
    CREATE USER {DB_USER} WITH PASSWORD '{DB_PASS}';
    RAISE NOTICE 'User {DB_USER} created';
  ELSE
    ALTER USER {DB_USER} WITH PASSWORD '{DB_PASS}';
    RAISE NOTICE 'User {DB_USER} password reset to gabeseye2024';
  END IF;
END $$;
"""):
    print("\nEchec. Vérifie que PostgreSQL est démarré et le mot de passe correct.")
    sys.exit(1)

# Step 2 — create database (separate call, outside transaction)
db_exists_result = subprocess.run(
    [PSQL, "-h", "localhost", "-p", "5432", "-U", "postgres", "-d", "postgres",
     "-tAc", f"SELECT 1 FROM pg_database WHERE datname='{DB_NAME}'"],
    input=b"",
    env={**os.environ, "PGPASSWORD": pg_password, "PGCLIENTENCODING": "UTF8"},
    capture_output=True,
)
if db_exists_result.stdout.strip() != b"1":
    psql(
        f"CREATE DATABASE {DB_NAME} OWNER {DB_USER} "
        f"ENCODING 'UTF8' LC_COLLATE 'C' LC_CTYPE 'C' TEMPLATE template0;"
    )
    print(f"✓ Base '{DB_NAME}' créée")
else:
    print(f"  Base '{DB_NAME}' existe déjà")

# Step 3 — grant privileges
psql(f"GRANT ALL PRIVILEGES ON DATABASE {DB_NAME} TO {DB_USER};")
psql(f"GRANT ALL ON SCHEMA public TO {DB_USER};", dbname=DB_NAME)
psql(f"ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO {DB_USER};", dbname=DB_NAME)

print("\nBase PostgreSQL prête. Lance maintenant :")
print("  venv/Scripts/uvicorn app.main:app --reload --port 8000")
print("  venv/Scripts/python seed.py")
