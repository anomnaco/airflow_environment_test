#!/bin/bash
set -e

# Start PostgreSQL service
service postgresql start

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL to start..."
sleep 5

# Set PostgreSQL environment variables
export PGUSER=postgres
export PGPASSWORD=postgres

# Configure PostgreSQL
su - postgres -c psql <<EOF
-- Create Airflow database
CREATE USER airflow_user WITH PASSWORD 'airflow_pass';
CREATE DATABASE airflow_db OWNER airflow_user;

-- Grant all privileges on the Airflow database to the Airflow user
GRANT ALL PRIVILEGES ON DATABASE airflow_db TO airflow_user;

ALTER SCHEMA public OWNER TO airflow_user;
GRANT USAGE ON SCHEMA public TO airflow_user;
GRANT CREATE ON SCHEMA public TO airflow_user;
EOF

# Initialize Airflow (this creates the default airflow.cfg)
airflow db init

# Configure Airflow to use PostgreSQL
AIRFLOW_CONFIG=${AIRFLOW_HOME}/airflow.cfg

# Modify airflow.cfg as per specifications
# executor = LocalExecutor
sed -i 's/^executor = .*/executor = LocalExecutor/' $AIRFLOW_CONFIG

# parallelism = 16
sed -i 's/^parallelism = .*/parallelism = 16/' $AIRFLOW_CONFIG

# load_examples = False
sed -i 's/^load_examples = .*/load_examples = False/' $AIRFLOW_CONFIG

# sql_alchemy_conn = postgresql+psycopg2://airflow_user:airflow_pass@localhost/airflow_db
sed -i "s|^sql_alchemy_conn =.*|sql_alchemy_conn = postgresql+psycopg2://airflow_user:airflow_pass@localhost/airflow_db|" $AIRFLOW_CONFIG

# auth_backends = airflow.api.auth.backend.session, airflow.providers.fab.auth_manager.api.auth.backend.basic_auth
sed -i "s|^auth_backends =.*|auth_backends = airflow.api.auth.backend.session, airflow.providers.fab.auth_manager.api.auth.backend.basic_auth|" $AIRFLOW_CONFIG

# Initialize Airflow database again with the new configuration
airflow db init

# Create Airflow admin user
airflow users create \
    --username admin \
    --firstname Admin \
    --lastname User \
    --role Admin \
    --email admin@example.com \
    --password admin

# Start Airflow Scheduler and Webserver in the background
airflow scheduler &
airflow webserver