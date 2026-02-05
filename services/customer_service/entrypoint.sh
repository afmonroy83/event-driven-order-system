#!/bin/bash
set -e

echo "Waiting for RabbitMQ..."
while ! nc -z rabbitmq 5672; do
  sleep 1
done

echo "Starting OrderCreatedConsumer..."
bundle exec rails runner 'OrderCreatedConsumer.start'
