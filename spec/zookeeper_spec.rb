require 'spec_helper'
require 'shared/connection_examples'


describe 'Zookeeper' do
  let(:path) { "/_zktest_" }
  let(:data) { "underpants" } 
  let(:zk_host) { 'localhost:2181' }

  def zk
    @zk
  end

  before do
    @zk = Zookeeper.new(zk_host)
  end

  after do
    @zk.close

    wait_until do 
      begin
        !@zk.connected?
      rescue RuntimeError
        true
      end
    end
  end

#   let(:zk) do
#     Zookeeper.logger.debug { "creating root instance" }
#     Zookeeper.new(zk_host)
#   end

  it_should_behave_like "connection"
end

