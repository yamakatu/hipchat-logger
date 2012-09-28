module HipChat
  class Client
    include HTTParty

    base_uri 'https://api.hipchat.com/v1/rooms'
    format :json

    def initialize(token)
      @token = token
    end

    def rooms
      @rooms ||= self.class.get("/list", :query => {:auth_token => @token})['rooms'].
        map { |r| Room.new(@token, r) }
    end

    def [](name)
      Room.new(@token, :room_id => name)
    end
  end
end