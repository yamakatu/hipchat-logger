#!/usr/bin/env ruby
require 'bundler/setup'
require File.expand_path('../lib/hipchat', __FILE__)
require File.expand_path('../lib/hipchatlogger', __FILE__)

# Initialize and Run HipLogger
logger = HipChatLogger::HipLogger.new
logger.run