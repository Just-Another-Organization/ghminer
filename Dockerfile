FROM ruby:3.0

ENV APP_PATH /app

WORKDIR $APP_PATH/
ADD Gemfile* $APP_PATH/
RUN gem install bundler
RUN bundle config set --local path '$APP_PATH/vendor/bundle'
RUN bundle install
RUN bundle update

ADD . $APP_PATH

EXPOSE 4567

CMD ["bundle", "exec", "rackup", "-p", "4567", "--host", "0.0.0.0"]
