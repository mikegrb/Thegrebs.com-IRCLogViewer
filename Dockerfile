FROM        perl:latest
MAINTAINER  Mike Greb michael@thegrebs.com

RUN curl -L http://cpanmin.us | perl - App::cpanminus
RUN cpanm Starman

ADD . /TGIRC
RUN cd /TGIRC && cpanm --installdeps .

EXPOSE 8080

ENV TGIRC_LOG_PATH /irclogs

WORKDIR /TGIRC
CMD exec starman --port 8080 script/TGIRC.pl
