module Zookeeper
  module Constants
    include ACLs

    ZKRB_GLOBAL_CB_REQ   = -1

    # file type masks
    ZOO_EPHEMERAL = 1
    ZOO_SEQUENCE  = 2
    
    # session state
    ZOO_EXPIRED_SESSION_STATE  = -112
    ZOO_AUTH_FAILED_STATE      = -113
    ZOO_CLOSED_STATE           = 0
    ZOO_CONNECTING_STATE       = 1
    ZOO_ASSOCIATING_STATE      = 2
    ZOO_CONNECTED_STATE        = 3
    
    # watch types
    ZOO_CREATED_EVENT      = 1
    ZOO_DELETED_EVENT      = 2
    ZOO_CHANGED_EVENT      = 3
    ZOO_CHILD_EVENT        = 4
    ZOO_SESSION_EVENT      = -1
    ZOO_NOTWATCHING_EVENT  = -2

    # exceptions/errors
    ZOK                    =  0
    ZSYSTEMERROR           = -1
    ZRUNTIMEINCONSISTENCY  = -2
    ZDATAINCONSISTENCY     = -3
    ZCONNECTIONLOSS        = -4
    ZMARSHALLINGERROR      = -5
    ZUNIMPLEMENTED         = -6
    ZOPERATIONTIMEOUT      = -7
    ZBADARGUMENTS          = -8
    ZINVALIDSTATE          = -9
    
    # api errors
    ZAPIERROR                 = -100
    ZNONODE                   = -101
    ZNOAUTH                   = -102
    ZBADVERSION               = -103
    ZNOCHILDRENFOREPHEMERALS  = -108
    ZNODEEXISTS               = -110
    ZNOTEMPTY                 = -111
    ZSESSIONEXPIRED           = -112
    ZINVALIDCALLBACK          = -113
    ZINVALIDACL               = -114
    ZAUTHFAILED               = -115
    ZCLOSING                  = -116
    ZNOTHING                  = -117
    ZSESSIONMOVED             = -118

                
    def print_events
      puts "ZK events:"
      # XXX: yeeeech, fix Constants.print_events
      Constants.constants.each do |c|
        puts "\t #{c}" if c =~ /^ZOO..*EVENT$/
      end
    end

    def print_states
      puts "ZK states:"
      # XXX: yeeeech, fix Constants.print_states
      Constants.constants.each do |c|
        puts "\t #{c}" if c =~ /^ZOO..*STATE$/
      end
    end

    def event_by_value(v)
      return unless v
      # XXX: yeeeech, fix Constants.event_by_value
      Constants.constants.each do |c|
        next unless c =~ /^ZOO..*EVENT$/
        if eval("Zookeeper::Constants::#{c}") == v
          return c
        end
      end
    end
    
    def state_by_value(v)
      return unless v
      # XXX: yeeeech, fix Constants.state_by_value
      Constants.constants.each do |c|
        next unless c =~ /^ZOO..*STATE$/
        if eval("Zookeeper::Constants::#{c}") == v
          return c
        end
      end
    end
  end
end
