FROM ruby:2.6-alpine

MAINTAINER Ryan Davis

WORKDIR /usr/src/app

RUN gem install --silent hoe minitest rake && \
    gem install --silent flog -N -v "~> 4.6" # currently 4.6.2

RUN adduser -u 9000 -D -h /usr/src/app -s /bin/false app
COPY . /usr/src/app
RUN chown -R app:app /usr/src/app

USER app

VOLUME /code
WORKDIR /code

CMD ["/usr/src/app/bin/codeclimate-flog"]
