#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'

Bundler.require(:default)

Dotenv.load('.env')

require "./app/app"

run Resizer