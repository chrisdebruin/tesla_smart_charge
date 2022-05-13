FROM ruby:2.7.5-slim

RUN apt-get update && apt-get install -y git build-essential libsqlite3-dev

WORKDIR /usr/src/app

COPY Gemfile Gemfile
COPY Gemfile.lock Gemfile.lock

RUN gem install bundler

RUN bundle install

COPY . .

CMD bundle exec ruby tesla.rb
