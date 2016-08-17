require 'spec_helper'

describe Regextest do
  it 'has a version number' do
    expect(Regextest::VERSION).not_to be nil
  end

  let(:regex) { Regextest.new("foo") }

  it 'is an instance of Regextest' do
    expect(regex).to be_a(Regextest)
  end

  it 'can generate string' do
    expect(regex.generate.to_s).to eq("foo")
  end
end
