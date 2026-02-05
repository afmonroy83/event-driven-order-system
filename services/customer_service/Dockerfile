FROM ruby:3.3-slim

RUN apt-get update -qq && apt-get install -y \
  build-essential \
  libpq-dev \
  libyaml-dev \
  pkg-config \
  git \
  curl \
  nodejs \
  postgresql-client \
  netcat-openbsd \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

EXPOSE 3001

CMD ["bash", "-c", "rm -f tmp/pids/server.pid && rails s -b 0.0.0.0"]
