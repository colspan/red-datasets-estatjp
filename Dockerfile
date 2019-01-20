FROM ruby:2.5

RUN apt-get update \
    && apt-get install -y locales

RUN locale-gen ja_JP.UTF-8  
ENV LANG ja_JP.UTF-8  
ENV LANGUAGE ja_JP:en  
ENV LC_ALL ja_JP.UTF-8
