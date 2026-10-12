require 'spec_helper'

RSpec.describe KJess::Request::Set do
  it 'converts to the protocol' do
    request = KJess::Request::Set.new(:queue_name => 'test', :data => 'a job')
    expect(request.to_protocol).to eq("SET test 0 0 5\r\na job\r\n")
  end

  it 'sets the expiration time' do
    request = KJess::Request::Set.new(:queue_name => 'test', :expiration => 42, :data => 'a job')
    expect(request.to_protocol).to eq("SET test 0 42 5\r\na job\r\n")
  end
end
