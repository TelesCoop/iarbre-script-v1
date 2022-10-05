FROM python:slim

# WORKDIR /usr/src/app 
WORKDIR /app 

COPY ./scripts/requirements.txt requirements.txt

# for pyproj dependency
RUN export PROJ_DIR=/usr/share/pyproj
RUN pip install --no-cache-dir -r requirements.txt

COPY ./scripts ./
COPY ./sql ./
COPY ./env.$NAMESPACE_ENV ./

RUN ls -l .

CMD [ "python3", "./scripts/hello-world.py" ]