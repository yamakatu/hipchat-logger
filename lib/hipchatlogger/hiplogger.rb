#logger.rb
module HipChatLogger
  class HipLogger
    require 'optparse'
    require 'logger'
    require 'yaml'
    require 'erb'

    def initialize()
      @config = YAML.load(open(File.expand_path('../../../config/config.yml', __FILE__)))
      @params ||= ARGV.getopts("l:", "d:")
      
      initialize_logging
      set_hipchat_date
      
      @log.info "Starting hipchat-logger..."
      @output_template = ERB.new(File.read(File.expand_path('../../../views/splunk.erb', __FILE__)))
      @log.debug "Found and loaded ERB template file"

      connect_to_hipchat

    end

    #attr_reader :config, :template, :output_template, :log, :client

    def run
      @rooms = []

      # Get a list of all the rooms
      @rooms = @client.rooms
      @log.info "Getting history of all #{@rooms.count} room(s) for #{@config['log_date']}..."
      @rooms.each do |room|
        @log.debug "Getting history of room=#{room.name}, room_id=#{room.room_id}, date=#{@config['log_date']}"

        # Get messages for this room
        begin
          room_messages = []
          skipped_messages = 0
          room_messages = room.messages(@config['log_date'])
        rescue Exception => e
          @log.debug e.message
        end

        # Log messages for this room 
        if room_messages.count > 0
          # Open room log file for writing
          room_log_file_name = "hipchat_room_id_#{room.room_id}_#{@config['log_date']}.log"
          log_file = File.open('log/'+room_log_file_name, 'w')
          
          room_messages.each do |message|
            # Look up netid
            message.author_netid = @config["user_netid_mappings"][message.author.downcase.gsub(/\s/,'')] if @config["user_netid_mappings"].has_key? message.author.downcase.gsub(/\s/,'')

            # log output using erb template unless the user is supposed to be ignored
            if @config["ignored_users"].include?(message.user_id) || @config["ignored_users"].include?(message.author_id)
              @log.debug "Skipping Message -- Matched '#{message.author}' or '#{message.author_id}' to the @config['ignored_users'] list."
              skipped_messages = skipped_messages + 1
            else
              log_file.write @output_template.result(message.get_binding)
            end
          end
          @log.info "Logged #{room.message_count - skipped_messages} messages for '#{room.name}' (room_id=#{room.room_id}) to #{log_file.path}"
        else
          @log.debug "There were 0 messages found for '#{room.name}' (room_id=#{room.room_id}) on #{@config['log_date']}.}"
        end
      end

      @log.info "Finished logging hipchat messages for #{@config['log_date']}."

    end

    private


    def initialize_logging

      Dir.mkdir('log') unless Dir.exist?('log')

      @log = Logger.new('log/hipchat_logger.log', 'daily') # TODO: Create log directory if it doesn't exist

      case @params["l"]
      when 'debug'
        @log.level = Logger::DEBUG
      when 'error'
        @log.level = Logger::ERR
      when 'warn'
        @log.level = Logger::WARN
      else
        @log.level = Logger::INFO
      end
    end

    def set_hipchat_date
      # use what is passed through '-d' if given -- Example: '-d 2012-09-27'
      @config["log_date"] = (@params["d"] ? @params["d"] : Time.now.strftime('%Y-%m-%d'))
    end

    def connect_to_hipchat
      begin
        @client = HipChat::Client.new(@config["hipchat"]["api"]["key"])
      rescue Exception => e
        @log.error e.message
      end

      @log.debug "Successfully connected to HipChat"
    end
  end
end

