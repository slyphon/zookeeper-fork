module Zookeeper
  class Client
    if defined?(::JRUBY_VERSION)
      include Zookeeper::JavaBase
    end

    include ClientMethods
  end
end

