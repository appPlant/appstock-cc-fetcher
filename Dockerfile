FROM alpine:3.3
MAINTAINER Sebastian Katzer "katzer@appplant.de"

ENV BUILD_PACKAGES ruby-dev libffi-dev libxml2-dev libxslt-dev gcc make libc-dev
ENV RUBY_PACKAGES ruby curl libxml2 libxslt ruby-bundler ruby-io-console

RUN apk update && \
    apk add --no-cache $BUILD_PACKAGES && \
    apk add --no-cache $RUBY_PACKAGES

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

RUN alias ll='ls --color=auto -l'
RUN alias rake="cd $APP_HOME && bundle exec rake"

CMD ["crond", "-f", "-d", "8"]
CMD ["bundle", "exec", "rake", "check:drive"]
