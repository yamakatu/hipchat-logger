require 'bundler/setup'
require 'yaml'
require File.expand_path('../lib/hipchat', __FILE__)
require 'erb'
require 'logger'

# Define log file
log = Logger.new('log/hipchat_logger.log', 'daily')

# Load config
config = YAML.load(open(File.expand_path('../config/config.yml', __FILE__)))

# ERB Template
log_output = ERB.new(File.read('views/splunk.erb'))

# Connect to HipChat
client = HipChat::Client.new(config["hipchat"]["api"]["key"])

# DATES
today = Time.now
yesterday = today - (24*60*60)

log_date = yesterday.strftime('%Y-%m-%d')
# Loop through HipChat Rooms
client.rooms.each do |room|

  # Open room log file for writing
  log_file = File.open("log/hipchat_room_id_#{room.room_id}_#{log_date}.log", 'w')

  begin
    room.messages(log_date).each do |message|
      # Look up netid
      message.author_netid = "jeffs" if config["user_mappings"].has_key? message.author.downcase.gsub(/\s/,'')

      # log output using erb template
      log_file.write log_output.result(message.get_binding)
    end
  rescue Exception => e
    log.warn e.message
  end
end
