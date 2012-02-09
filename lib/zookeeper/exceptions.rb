module Zookeeper
  module Exceptions
    include Constants

    class ZookeeperException < StandardError
    end

    class EverythingOk            < ZookeeperException; end
    class SystemError             < ZookeeperException; end
    class RunTimeInconsistency    < ZookeeperException; end
    class DataInconsistency       < ZookeeperException; end
    class ConnectionLoss          < ZookeeperException; end
    class MarshallingError        < ZookeeperException; end
    class Unimplemented           < ZookeeperException; end
    class OperationTimeOut        < ZookeeperException; end
    class BadArguments            < ZookeeperException; end
    class InvalidState            < ZookeeperException; end
    class ApiError                < ZookeeperException; end
    class NoNode                  < ZookeeperException; end
    class NoAuth                  < ZookeeperException; end
    class BadVersion              < ZookeeperException; end
    class NoChildrenForEphemerals < ZookeeperException; end
    class NodeExists              < ZookeeperException; end
    class NotEmpty                < ZookeeperException; end
    class SessionExpired          < ZookeeperException; end
    class InvalidCallback         < ZookeeperException; end
    class InvalidACL              < ZookeeperException; end
    class AuthFailed              < ZookeeperException; end
    class Closing                 < ZookeeperException; end
    class Nothing                 < ZookeeperException; end
    class SessionMoved            < ZookeeperException; end
    
    # these are Ruby client exceptions
    class ConnectionClosed        < ZookeeperException; end
    class NotConnected            < ZookeeperException; end 
    class ShuttingDownException   < ZookeeperException; end
    class DataTooLargeException   < ZookeeperException; end
    
    def self.by_code(code)
      case code
      when ZOK then EverythingOk
      when ZSYSTEMERROR then SystemError
      when ZRUNTIMEINCONSISTENCY then RunTimeInconsistency
      when ZDATAINCONSISTENCY then DataInconsistency
      when ZCONNECTIONLOSS then ConnectionLoss
      when ZMARSHALLINGERROR then MarshallingError
      when ZUNIMPLEMENTED then Unimplemented
      when ZOPERATIONTIMEOUT then OperationTimeOut
      when ZBADARGUMENTS then BadArguments
      when ZINVALIDSTATE then InvalidState
      when ZAPIERROR then ApiError
      when ZNONODE then NoNode
      when ZNOAUTH then NoAuth
      when ZBADVERSION then BadVersion
      when ZNOCHILDRENFOREPHEMERALS then NoChildrenForEphemerals 
      when ZNODEEXISTS then NodeExists              
      when ZNOTEMPTY then NotEmpty                
      when ZSESSIONEXPIRED then SessionExpired          
      when ZINVALIDCALLBACK then InvalidCallback         
      when ZINVALIDACL then InvalidACL
      when ZAUTHFAILED then AuthFailed
      when ZCLOSING then Closing
      when ZNOTHING then Nothing
      when ZSESSIONMOVED then SessionMoved
      else 
        raise "no exception defined for code #{code}"
      end
    end
    
    def self.raise_on_error(code)
      exc = self.by_code(code)
      raise exc unless exc == EverythingOk
    end
  end
end
