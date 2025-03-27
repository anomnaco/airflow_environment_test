# Use Ubuntu 24.10 as the base image
FROM ubuntu:24.10

# Set environment variable to suppress interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Set environment variables for Airflow
ENV AIRFLOW_HOME=/root/airflow
ENV VENV_PATH=/airflowenv
ENV PATH=$VENV_PATH/bin:$PATH

# Install APT dependencies
COPY apt-dependencies.txt /tmp/apt-dependencies.txt
RUN apt-get update && \
    apt-get install -y $(cat /tmp/apt-dependencies.txt) && \
    rm /tmp/apt-dependencies.txt && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set up Python virtual environment
RUN python3 -m venv $VENV_PATH

# Upgrade pip and install Python requirements
COPY requirements.txt /tmp/requirements.txt
RUN pip install --upgrade pip && \
    pip install -r /tmp/requirements.txt && \
    rm /tmp/requirements.txt

# Create Airflow directory
RUN mkdir -p $AIRFLOW_HOME

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose Airflow webserver port
EXPOSE 8080

# Set the entrypoint
ENTRYPOINT ["/entrypoint.sh"]