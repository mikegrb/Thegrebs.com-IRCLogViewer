FROM        perl:latest
MAINTAINER  Mike Greb michael@thegrebs.com

RUN curl -L http://cpanmin.us | perl - App::cpanminus
RUN cpanm Starman Mojolicious Date::Calc URI::Find HTML::CalendarMonth

EXPOSE 8080
ENV TGIRC_LOG_PATH /irclogs

ADD . /TGIRC
WORKDIR /TGIRC

CMD exec starman --port 8080 script/TGIRC.pl
