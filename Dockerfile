FROM ruby:2.7

WORKDIR /usr/src/app

RUN gem install bundler

COPY Gemfile Gemfile.lock ./

RUN bundle install

CMD bundle exec ruby tesla.rb
