require File.expand_path('../spec_helper', __FILE__)
require 'zookeeper/em_client'

gem 'evented-spec', '~> 0.9.0'
require 'evented-spec'


describe 'Zookeeper' do
  describe 'EMClient' do
    include EventedSpec::SpecHelper
    default_timeout 3.0

    def setup_zk
      @zk = Zookeeper::EMClient.new('localhost:2181')
      em do
        @zk.on_attached do
          yield
        end
      end
    end

    def teardown_and_done
      @zk.close do 
        logger.debug { "TEST: about to call done" }
        EM.next_tick do
          done
        end
      end
    end

    describe 'selectable_io' do
      it %[should return an IO object] do
        setup_zk do
          @zk.selectable_io.should be_instance_of(IO)
          teardown_and_done
        end
      end

      it %[should not be closed] do
        setup_zk do
          @zk.selectable_io.should_not be_closed
          teardown_and_done
        end
      end

      before do
        @data_cb = Zookeeper::Callbacks::DataCallback.new do
          logger.debug { "cb called: #{@data_cb.inspect}" }
        end
      end

      it %[should be read-ready if there's an event waiting] do
        setup_zk do
          @zk.get(:path => "/", :callback => @data_cb)

          r, *_ = IO.select([@zk.selectable_io], [], [], 2)

          r.should be_kind_of(Array)

          teardown_and_done
        end
      end
    end

    describe 'em_connection' do
      before do
        @zk = Zookeeper::EMClient.new('localhost:2181')
      end

      it %[should be nil before the reactor is started] do
        @zk.em_connection.should be_nil

        em do
          teardown_and_done
        end
      end

      it %[should fire off the on_attached callbacks once the reactor is managing us] do
        @zk.on_attached do |*|
          @zk.em_connection.should_not be_nil
          @zk.em_connection.should be_instance_of(Zookeeper::ZKEMConnection)
          teardown_and_done
        end

        em do
          EM.reactor_running?.should be_true
        end
      end
    end

    describe 'callbacks' do
      it %[should be called on the reactor thread] do
        cb = lambda do |h|
          EM.reactor_thread?.should be_true
          logger.debug { "called back on the reactor thread? #{EM.reactor_thread?}" }
          teardown_and_done
        end

        setup_zk do
          @zk.on_attached do |*|
            logger.debug { "on_attached called" }
            rv = @zk.get(:path => '/', :callback => cb) 
            logger.debug { "rv from @zk.get: #{rv.inspect}" }
          end
        end
      end
    end

  end
end


