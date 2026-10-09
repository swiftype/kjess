require 'spec_helper'

RSpec.describe 'KJess::VERSION' do
  it 'should have a #.#.# format' do
    expect(KJess::VERSION).to match(/\A\d+\.\d+\.\d+\Z/)
    expect(KJess::VERSION.to_s).to match(/\A\d+\.\d+\.\d+\Z/)
  end
end
