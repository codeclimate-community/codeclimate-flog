FROM ruby:2.3-alpine

MAINTAINER Ryan Davis

WORKDIR /usr/src/app

RUN gem install flog -N

RUN adduser -u 9000 -D -h /usr/src/app -s /bin/false app
COPY . /usr/src/app
RUN chown -R app:app /usr/src/app

USER app

VOLUME /code
WORKDIR /code

CMD ["/usr/src/app/bin/codeclimate-flog"]