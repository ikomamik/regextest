require 'spec_helper'

describe Regtest do
  it 'has a version number' do
    expect(Regtest::VERSION).not_to be nil
  end

  let(:regex) { Regtest.new("foo") }

  it 'is an instance of Regtest' do
    expect(regex).to be_a(Regtest)
  end

  it 'can generate string' do
    expect(regex.generate.to_s).to eq("foo")
  end
end
