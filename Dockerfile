FROM alpine:3.3
MAINTAINER Sebastian Katzer "katzer@appplant.de"

ENV BUILD_PACKAGES ruby-dev libffi-dev libxslt-dev gcc make libc-dev tzdata
ENV RUBY_PACKAGES ruby curl libxslt ruby-bundler ruby-io-console

RUN apk update && \
    apk add --no-cache $BUILD_PACKAGES && \
    apk add --no-cache $RUBY_PACKAGES

RUN cp /usr/share/zoneinfo/Europe/Berlin /etc/localtime
RUN echo "Europe/Berlin" >  /etc/timezone

ENV APP_HOME /usr/app/
RUN mkdir $APP_HOME
RUN mkdir $APP_HOME/log
WORKDIR $APP_HOME

COPY Gemfile $APP_HOME
COPY Gemfile.lock $APP_HOME
RUN bundle config path vendor/bundle
RUN bundle config build.nokogiri --use-system-libraries
RUN bundle install --no-cache --without development test

RUN apk del $BUILD_PACKAGES && \
    rm -rf /var/cache/apk/* && \
    rm -rf /usr/share/ri

COPY . $APP_HOME

COPY scripts/ /etc/periodic/
RUN chmod -R +x /etc/periodic/

CMD ["crond", "-f", "-d", "8"]
