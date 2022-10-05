FROM python:3

WORKDIR /usr/src/app

COPY ./scripts/requirements.txt ./

# for pyproj dependency
RUN export PROJ_DIR=/usr/local
RUN pip install --no-cache-dir -r requirements.txt

COPY ./scripts ./
COPY ./sql ./
COPY ./env.$NAMESPACE_ENV ./

RUN ls -l .

CMD [ "python", "./scripts/hello-world.py" ]