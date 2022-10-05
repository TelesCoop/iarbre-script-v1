FROM python:3

WORKDIR /usr/src/app

RUN echo "-----------------------"
RUN echo "    Python3 Image"
RUN echo "-----------------------"

COPY scripts/requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY ./scripts .

CMD [ "python", "./hello-world.py" ]