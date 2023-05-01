FROM ghcr.io/dbt-labs/dbt-postgres:1.5.0

# Set workdir
WORKDIR /app

# copy dbt profile
COPY .dbt/profiles.yml /root/.dbt/profiles.yml

# copy dbt project
COPY . /app

# default entrypoint
ENTRYPOINT ["dbt", "debug"]
