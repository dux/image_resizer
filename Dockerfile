FROM ruby:2.7.0

RUN apt-get update -y && apt-get purge -y --auto-remove

ENV BUNDLER_VERSION 2.0.2
ENV APP_HOME /app
ENV RESIZER_SECRET=secret
ENV RESIZER_SERVER=http://localhost:4000
ENV RACK_ENV=development

RUN gem install bundler --version "$BUNDLER_VERSION"

RUN mkdir $APP_HOME
RUN mkdir $APP_HOME/log

WORKDIR $APP_HOME
COPY . $APP_HOME

RUN bundle install --jobs 3 --retry 3
RUN rake install
# RUN rspec
