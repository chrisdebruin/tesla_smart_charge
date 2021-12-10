FROM ruby:2.7.5-slim

RUN apt-get update && apt-get install -y git ubuntu-dev-tools libsqlite3-dev

WORKDIR /usr/src/app

RUN gem install bundler

COPY Gemfile Gemfile.lock ./

RUN bundle install

CMD bundle exec ruby tesla.rb
