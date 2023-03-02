# Use an official Python runtime as a parent image
FROM python:3.9-slim-buster

# Set the working directory to /app
WORKDIR /app

# Add a non-root user to run the application
RUN groupadd -r calquluser && useradd --no-log-init -r -g calquluser calquluser

# Copy the current directory contents into the container at /app
COPY . /app

# Install any needed packages specified in requirements.txt
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        libgdal-dev \
        pkg-config \
        python3-gi \
        python3-gi-cairo && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir --no-deps --disable-pip-version-check -r requirements.txt && \
    rm -rf /root/.cache

# Change ownership of the application to the non-root user
RUN chown -R calquluser:calquluser /app

# Switch to the non-root user
USER calquluser

# Define the arguments for the Dockerfile
ARG NAMESPACE_ENV
ARG DB_HOST
ARG DB_PORT
ARG DB_NAME
ARG DB_USER

# Set the environment variables for the arguments
ENV NS_ENV=$NS_ENV
ENV DB_HOST="$DB_HOST_ENV-$NAMESPACE_ENV"
ENV DB_PORT=$DB_PORT
ENV DB_NAME=$DB_NAME
ENV DB_USER=$DB_USER

# Set the environment variable for PROJ_LIB
ENV PROJ_LIB=/usr/share/proj/

# Run the command to start the Python script
CMD ["/bin/bash", "-c", "/app/launch.sh $NS_ENV $DB_HOST $DB_PORT $DB_NAME $DB_USER"]