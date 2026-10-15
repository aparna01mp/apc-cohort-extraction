from pathlib import Path
import sqlite3
import pandas as pd


# =============================================================================
# Configuration
# =============================================================================

# Folder containing this Python script and the APC CSV files
csv_folder = Path(__file__).resolve().parent

# SQLite database location
db_path = csv_folder.parent.parent / "apc_interview.db"

# Name of the raw APC table
table_name = "apc_raw"


# =============================================================================
# Find all APC CSV files
# =============================================================================

csv_files = sorted(csv_folder.glob("*.csv"))

print(f"CSV folder: {csv_folder}")
print(f"Database: {db_path}")
print(f"CSV files found: {len(csv_files)}")

if not csv_files:
    raise FileNotFoundError("No CSV files were found in the folder.")


# =============================================================================
# Connect to SQLite
# =============================================================================

conn = sqlite3.connect(db_path)


# =============================================================================
# Drop existing raw table
# =============================================================================

# This makes the script safe to rerun without duplicating rows
conn.execute(f"DROP TABLE IF EXISTS {table_name}")
conn.commit()


# =============================================================================
# Load all CSV files into one SQLite table
# =============================================================================

total_rows = 0

for i, csv_file in enumerate(csv_files, start=1):

    print(f"\n[{i}/{len(csv_files)}] Loading: {csv_file.name}")

    # Read all columns as strings to preserve identifiers and coded values
    df = pd.read_csv(
        csv_file,
        dtype=str,
        low_memory=False
    )

    # Add original file name for traceability
    df["SOURCE_FILE"] = csv_file.name

    # First CSV creates the table, remaining CSVs are appended
    if i == 1:
        df.to_sql(
            table_name,
            conn,
            if_exists="replace",
            index=False
        )
    else:
        df.to_sql(
            table_name,
            conn,
            if_exists="append",
            index=False
        )

    total_rows += len(df)

    print(f"Rows loaded from file: {len(df):,}")
    print(f"Running total:         {total_rows:,}")


# =============================================================================
# Validate completed load
# =============================================================================

sqlite_row_count = conn.execute(
    f"SELECT COUNT(*) FROM {table_name}"
).fetchone()[0]


# =============================================================================
# Close database connection
# =============================================================================

conn.close()


# =============================================================================
# Final summary
# =============================================================================

print("\n===================================================")
print("APC data load complete")
print("===================================================")
print(f"Files loaded:        {len(csv_files)}")
print(f"Rows read from CSVs: {total_rows:,}")
print(f"Rows in SQLite:      {sqlite_row_count:,}")
print(f"SQLite table:        {table_name}")
print(f"Database:            {db_path}")