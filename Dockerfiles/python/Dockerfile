FROM python:latest

# WORKDIR /usr/src/app 
WORKDIR /app 

COPY ./scripts/pip_geopandas.txt pip_geopandas.sh
COPY ./scripts/requirements.txt requirements.txt
# for pyproj dependency
# RUN export PROJ_DIR=/usr/share/pyproj
# RUN export PROJ_DIR=/usr/local
# RUN export PROJ_WHEEL=true
# RUN pip install pyproj

RUN chmod +x pip_geopandas.sh && ./pip_geopandas.sh
RUN pip install --no-cache-dir -r requirements.txt

COPY ./scripts ./
COPY ./sql ./
COPY ./env.$NAMESPACE_ENV ./

RUN ls -l .

CMD [ "python3", "./scripts/hello-world.py" ]