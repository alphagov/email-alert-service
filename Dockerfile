FROM ruby:2.7.2
RUN gem install foreman

ENV RABBITMQ_HOSTS rabbitmq
ENV RABBITMQ_VHOST /
ENV RABBITMQ_USER guest
ENV RABBITMQ_PASSWORD guest
ENV RABBITMQ_EXCHANGE published_documents
ENV RAILS_ENV development
ENV REDIS_HOST redis

ENV APP_HOME /app
RUN mkdir $APP_HOME

WORKDIR $APP_HOME
ADD Gemfile* $APP_HOME/
RUN bundle install
ADD . $APP_HOME

CMD foreman run major-change-queue-consumer
