FROM ruby:3.0-alpine

RUN apk update
RUN apk add --update-cache  \
    build-base libc-dev linux-headers gcc tzdata
RUN rm -rf /var/cache/apk/*

ENV APP_PATH /app

WORKDIR $APP_PATH/
ADD Gemfile* $APP_PATH/
RUN gem install bundler
RUN bundle config set --local path "${APP_PATH}/vendor/bundle"
RUN bundle install
RUN bundle update

ADD . $APP_PATH

EXPOSE 4567

CMD ["bundle", "exec", "rackup", "-p", "4567", "--host", "0.0.0.0"]
