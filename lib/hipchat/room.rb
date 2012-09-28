module HipChat
  class Room < OpenStruct
    include HTTParty

    base_uri 'https://api.hipchat.com/v1/rooms'

    def initialize(token, params)
      @token = token

      super(params)
    end

    # DYNAMIC ROOM METHODS:
    #   room_id=102471
    #   name="Water Cooler"
    #   topic="Welcome! Send this link to coworkers who need accounts: https://www.hipchat.com/invite/27240/b5898e5fb2cd6a2586c1c53c4cd5eadb"
    #   last_active=1348768772
    #   created=1348528666
    #   owner_user_id=167249
    #   is_archived=false
    #   is_private=false 
    #   xmpp_jid="27240_biola_it_application_services@conf.hipchat.com">

    # Send a message to this room.
    #
    # Usage:
    #
    #   # Default
    #   send 'nickname', 'some message'
    #
    #   # Notify users and color the message red
    #   send 'nickname', 'some message', :notify => true, :color => 'red'
    #
    #   # Notify users (deprecated)
    #   send 'nickname', 'some message', true
    #
    # Options:
    #
    # +color+::  "yellow", "red", "green", "purple", or "random"
    #            (default "yellow")
    # +notify+:: true or false
    #            (default false)
    def send(from, message, options_or_notify = {})
      options = if options_or_notify == true or options_or_notify == false
        log.warn "DEPRECATED: Specify notify flag as an option (e.g., :notify => true)"
        { :notify => options_or_notify }
      else
        options_or_notify || {}
      end

      options = { :color => 'yellow', :notify => false }.merge options

      response = self.class.post('/message',
        :query => { :auth_token => @token },
        :body  => {
          :room_id        => room_id,
          :from           => from,
          :message        => message,
          :message_format => options[:message_format] || 'html',
          :color          => options[:color],
          :notify         => options[:notify] ? 1 : 0
        }
      )

      case response.code
      when 200; true
      when 404
        raise UnknownRoom,  "Unknown room: `#{room_id}'"
      when 401
        raise Unauthorized, "Access denied to room `#{room_id}'"
      else
        raise UnknownResponseCode, "Unexpected #{response.code} for room `#{room_id}'"
      end
    end
    
    def history(options_or_notify = {})
      options = if options_or_notify == true or options_or_notify == false
        warn "DEPRECATED: Specify notify flag as an option (e.g., :notify => true)"
        { :notify => options_or_notify }
      else
        options_or_notify || {}
      end

      options = { :color => 'yellow', :notify => false }.merge options

      response = self.class.get('/history',
        :query => { 
          :auth_token     => @token,
          :room_id        => room_id,
          :date           => Time.now.strftime('%Y-%m-%d'),
          :timezone       => Time.now.zone
        }
      )

      case response.code
      when 200; response.parsed_response["messages"]
      when 404
        raise UnknownRoom,  "Unknown room: `#{room_id}'"
      when 401
        raise Unauthorized, "Access denied to room `#{room_id}'"
      else
        raise UnknownResponseCode, "Unexpected #{response.code} for room `#{room_id}'"
      end
    end

    def messages (year_month_day = Time.now.strftime('%Y-%m-%d'))
      @year_month_day = year_month_day
      @messages ||= []
      if @messages.empty?
        response = self.class.get('/history',
          :query => { 
            :auth_token     => @token,
            :room_id        => room_id,
            :date           => @year_month_day,
            :timezone       => Time.now.zone
          }
        )

        case response.code
        when 200
          @messages = response.parsed_response['messages'].map { |m| Message.new(@token, m) }
        when 404
          raise UnknownRoom,  "Unknown room: `#{room_id}'"
        when 401
          raise Unauthorized, "Access denied to room `#{room_id}'"
        else
          raise UnknownResponseCode, "Unexpected #{response.code} for room `#{room_id}'"
        end
      end
    end

    def message_count
      @messages.count
    end
  end
end