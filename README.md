# APC Emergency Admissions Cohort Extraction

## Project Overview
This project demonstrates a Python and SQL workflow for loading Hospital Episode Statistics (HES) Admitted Patient Care (APC) sample data into a SQLite database and extracting an emergency admissions cohort.

## Dataset
- Artificial HES APC sample dataset
- Multiple CSV files containing hospital admission records
- Synthetic data used for demonstration purposes

## Tools and Technologies
- **Python** – Data loading and processing
- **Pandas** – Reading CSV files
- **SQLite** – Relational database storage
- **SQL** – Cohort extraction and querying
- **Git and GitHub** – Version control

## Workflow
1. Identify and read multiple APC CSV files using Python.
2. Load the records into a SQLite database.
3. Combine the records into a single raw data table.
4. Execute SQL queries to extract the required emergency admissions cohort.
5. Validate the extracted records and review patient and admission counts.

## Repository Files
- `load_apc_to_sqlite.py` – Python script for loading APC CSV files into SQLite.
- `apc_emergency_cohort_final.sql` – SQL script containing cohort extraction logic.

## Running the Project
1. Install Python and pandas.
2. Obtain the appropriate artificial APC sample dataset.
3. Place the CSV files in the same folder as the Python loader.
4. Run `python load_apc_to_sqlite.py`.
5. Open the resulting SQLite database and execute the SQL extraction script.

## Data Privacy
This repository contains code only. No patient-level data or healthcare datasets are included.
