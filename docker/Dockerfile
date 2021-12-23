FROM ciceron/ada-bionic:latest

MAINTAINER Stephane Carrez <Stephane.Carrez@gmail.com>

RUN apt-get update \
   && apt-get install -y sqlite3 unzip imagemagick pngcrush libjpeg-progs \
      liblzma-dev

RUN mkdir -p /usr/src \
   && cd /usr/src \
   && git clone --recursive https://gitlab.com/stcarrez/porion.git porion \
   && cd porion \
   && ./configure --prefix=/usr \
   && make -s \
   && make -s install

WORKDIR /usr/src/porion
