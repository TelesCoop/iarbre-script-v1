FROM python:3

WORKDIR /usr/src/app

# Get the NAMESPACE_ENV value. This should be 'd01', 'r01' or 'p01'
# ARG NAMESPACE_ENV="" 

# Remplacing values in file
COPY ./env.example ./env.$NAMESPACE_ENV

RUN sed -i "s/__POSTGRES_DB__/$POSTGRES_DB/g" ./env.$NAMESPACE_ENV && \
sed -i "s/__POSTGRES_PASSWORD__/$POSTGRES_PASSWORD/g" ./env.$NAMESPACE_ENV && \
sed -i "s/__POSTGRES_PORT__/$POSTGRES_PORT/g" ./env.$NAMESPACE_ENV && \
sed -i "s/__POSTGRES_SERVER__/$POSTGRES_SERVER/g" ./env.$NAMESPACE_ENV && \
sed -i "s/__POSTGRES_USER__/$POSTGRES_USER/g" ./env.$NAMESPACE_ENV && \
sed -i "s/__POSTGRES_SCHEMA__/$POSTGRES_SCHEMA/g" ./env.$NAMESPACE_ENV

RUN cat ./env.$NAMESPACE_ENV

COPY ./scripts/requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY ./scripts ./
COPY ./sql ./

RUN ls -l .

CMD [ "python", "./scripts/hello-world.py" ]