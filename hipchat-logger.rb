require 'bundler/setup'
require 'yaml'
require File.expand_path('../lib/hipchat', __FILE__)
require 'erb'
require 'logger'
require 'optparse'

# Define log file
log = Logger.new('log/hipchat_logger.log', 'daily')

params = ARGV.getopts("l:")

case params["l"]
when 'debug'
  log.level = Logger::DEBUG
when 'error'
  log.level = Logger::ERROR
when 'warn'
  log.level = Logger::WARN
else
  log.level = Logger::INFO
end

log.debug "params=#{params.inspect}"

# Load config
config = YAML.load(open(File.expand_path('../config/config.yml', __FILE__)))
log.debug "Found and loaded config file"

# ERB Template
log_output = ERB.new(File.read('views/splunk.erb'))
log.debug "Found and loaded ERB template file"

# Connect to HipChat
begin
  client = HipChat::Client.new(config["hipchat"]["api"]["key"])
rescue Exception => e
  log.error e.message
end

log.debug "Successfully connected to HipChat"

# DATES
today = Time.now
yesterday = today - (24*60*60)

log_date = yesterday.strftime('%Y-%m-%d')
log.info "Getting history of all rooms for #{log_date}"

# Loop through HipChat Rooms
client.rooms.each do |room|
  log.debug "Getting history of room=#{room.name}, room_id=#{room.room_id}, date=#{log_date}"
  # Open room log file for writing
  log_file = File.open("log/hipchat_room_id_#{room.room_id}_#{log_date}.log", 'w')

  begin
    room.messages(log_date).each do |message|
      # Look up netid
      message.author_netid = config["user_mappings"][message.author.downcase.gsub(/\s/,'')] if config["user_mappings"].has_key? message.author.downcase.gsub(/\s/,'')

      # log output using erb template
      log_file.write log_output.result(message.get_binding)
    end
    log.debug "Logged #{room.message_count} messages for '#{room.name}' (room_id=#{room.room_id}) to #{log_file.path}"
  rescue Exception => e
    log.debug "Logged 0 messages for '#{room.name}' (room_id=#{room.room_id}) to #{log_file.path}"
    log.warn e.message
  end
end

log.info "Finished logging hipchat messages for #{log_date}."
