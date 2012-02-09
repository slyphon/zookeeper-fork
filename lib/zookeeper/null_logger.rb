module Zookeeper
  # just a bogus logger to use as the default
  # does nothing, successfully
  class NullLogger
    def initialize(*a)
    end

    def debug(*a)
    end

    def info(*a)
    end

    def warn(*a)
    end

    def error(*a)
    end

    def fatal(*a)
    end

    def level=(*a)
    end
  end
end

