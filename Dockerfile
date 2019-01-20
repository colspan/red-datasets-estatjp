FROM ruby:2.5

RUN apt-get update \
    && apt-get install -y locales

# set locale
RUN locale-gen ja_JP.UTF-8
RUN localedef -f UTF-8 -i ja_JP ja_JP.UTF-8
ENV LANG ja_JP.UTF-8
ENV LANGUAGE ja_JP.UTF-8
ENV LC_ALL ja_JP.UTF-8
RUN echo "LANG=ja_JP.UTF-8" >> /etc/environment
RUN echo "LC_ALL=ja_JP.UTF-8" >> /etc/environment
