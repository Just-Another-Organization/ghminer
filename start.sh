#!/bin/bash
bundle config set --local path 'vendor/bundle'
bundle install
bundle exec ruby server.rb
