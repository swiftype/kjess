require 'spec_helper'

RSpec.describe KJess::Request::Version do
  it 'has a keyword' do
    expect(KJess::Request::Version.keyword).to eq('VERSION')
  end

  it 'converts to the protocol' do
    expect(KJess::Request::Version.new.to_protocol).to eq("VERSION\r\n")
  end

  it 'has a valid response' do
    expect(KJess::Request::Version.valid_responses.size).to eq(1)
  end
end
