require 'spec_helper'

module KJess::Spec
  # Named differently from the minitest copy's KJess::Spec::BadRequest so both suites can be loaded in one process
  class RspecBadRequest < KJess::Request
    keyword 'BADREQUEST'
    arity   1
  end
end

RSpec.describe KJess::ClientError do
  let(:client) { KJess::Spec.kjess_client }

  after { KJess::Spec.reset_server(client) }

  it 'raises a client error if we send an invalid command' do
    expect { client.send_recv(KJess::Spec::RspecBadRequest.new) }.to raise_error(KJess::ClientError)
  end
end
