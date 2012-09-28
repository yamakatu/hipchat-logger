module HipChat
  class Message < OpenStruct
    require 'date'

    def initialize(room_name, room_id, params)
      @room_name = room_name
      @room_id = room_id

      super(params)
    end

    # .
    #
    # Example Message Methods:
    #
    # #<HipChat::Message date="2012-09-27T10:48:23-0700", from={"name"=>"Jeff Silzer", "user_id"=>167249}, message="what if we didn't get emails?">
    # 
    # Or if there is an attachment
    #
    # #<HipChat::Message date="2012-09-27T10:04:02-0700", from={"name"=>"Will Borchardt", "user_id"=>168653}, file={"name"=>"garry.png", "size"=>10757, "url"=>"http://uploads.hipchat.com/27240/168653/qaof47agndcduqs/garry.png"}, message="so nice and compact :)">

    attr_reader :author_netid, :room_name, :room_id

    def author_name
      @author_name  ||= self.from["name"]
    end

    def author_id
      @author_id ||= self.from["user_id"]
    end

    alias :author :author_name

    def author_netid=(netid)
      @author_netid = netid
    end

    def local_time
      @local_time ||= DateTime.strptime(self.date).to_time
    end

    # REQUIRED FOR ERB
    def get_binding
      binding
    end
    
  end
end