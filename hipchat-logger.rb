require 'bundler/setup'
require 'yaml'
require File.expand_path('../lib/hipchat', __FILE__)
require 'erb'
require 'logger'
require 'optparse'

# Define log file
log = Logger.new('log/hipchat_logger.log', 'daily')
log.info "Starting hipchat-logger..."

params = ARGV.getopts("l:", "d:")

case params["l"]
when 'debug'
  log.level = Logger::DEBUG
when 'error'
  log.level = Logger::ERR
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

#############################################
#                                           #
#              HIPCHAT LOGGING              #
#                                           #
#############################################

# Connect to HipChat 
begin
  client = HipChat::Client.new(config["hipchat"]["api"]["key"])
rescue Exception => e
  log.error e.message
end

log.debug "Successfully connected to HipChat"

log_date = (params["d"] ? params["d"] : Time.now.strftime('%Y-%m-%d'))

@rooms = []

# Get a list of all the rooms
@rooms = client.rooms
log.info "Getting history of all #{@rooms.count} room(s) for #{log_date}..."
@rooms.each do |room|
  log.debug "Getting history of room=#{room.name}, room_id=#{room.room_id}, date=#{log_date}"

  # Get messages for this room
  begin
    room_messages = []
    room_messages = room.messages(log_date)
  rescue Exception => e
    log.debug e.message
  end

  # Log messages for this room 
  if room_messages.count > 0
    # Open room log file for writing
    log_file = File.open("log/hipchat_room_id_#{room.room_id}_#{log_date}.log", 'w')
    
    room_messages.each do |message|
      # Look up netid
      message.author_netid = config["user_netid_mappings"][message.author.downcase.gsub(/\s/,'')] if config["user_netid_mappings"].has_key? message.author.downcase.gsub(/\s/,'')

      # log output using erb template unless the user is supposed to be ignored
      log_file.write log_output.result(message.get_binding) unless config["ignored_users"].include?(message.user_id) || config["ignored_users"].include?(message.author_id)
    end
    log.info "Logged #{room.message_count} messages for '#{room.name}' (room_id=#{room.room_id}) to #{log_file.path}"
  else
    log.debug "There were 0 messages found for '#{room.name}' (room_id=#{room.room_id}) on #{log_date}.}"
  end
end

log.info "Finished logging hipchat messages for #{log_date}."
