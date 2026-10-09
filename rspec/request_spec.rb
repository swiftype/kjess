require 'spec_helper'

module KJess::Spec
  # Named differently from the minitest copy's KJess::Spec::TestRequest so both suites can be loaded in one process
  class RspecTestRequest < KJess::Request
    keyword 'TEST'
    arity   1

    def parse_options_to_args(opts)
      opts.values
    end
  end
end

# (the minitest copy describes KJess::Response here, which looks like a typo: these examples are about KJess::Request)
RSpec.describe KJess::Request do
  it 'defines a keyword for child classes' do
    expect(KJess::Spec::RspecTestRequest.keyword).to eq('TEST')
  end

  it 'uses a callback to parse the options to args' do
    request = KJess::Spec::RspecTestRequest.new(:foo => 'this')
    expect(request.args).to eq(%w[this])
  end

  it 'converts the request into a protocol stream' do
    request = KJess::Spec::RspecTestRequest.new(:foo => 'that')
    expect(request.to_protocol).to eq("TEST that\r\n")
  end

  it 'registers child classes' do
    expect(KJess::Request.registry['TEST']).to eq(KJess::Spec::RspecTestRequest)
  end
end
