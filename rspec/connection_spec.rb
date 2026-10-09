require 'spec_helper'

RSpec.describe KJess::Connection do
  it 'returns a callable for the factory' do
    expect(KJess::Connection.socket_factory).to respond_to(:call)
  end

  it 'has a default factory that returns a KJess::Socket' do
    factory = KJess::Connection.socket_factory
    socket = factory.call(:port => KJess::Spec.memcache_port, :host => 'localhost')
    expect(socket.instance_of?(KJess::Socket)).to eq(true)
  end
end
