require 'httparty'
require 'ostruct'

module HipChat
  class UnknownRoom         < StandardError; end
  class Unauthorized        < StandardError; end
  class UnknownResponseCode < StandardError; end
  
  require_relative 'hipchat/client'
  require_relative 'hipchat/room'
  require_relative 'hipchat/message'

end