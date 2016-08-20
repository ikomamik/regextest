require 'spec_helper'

describe Regexp do
  let(:regex) { /foo/ }

  it 'is an instance of Regexp' do
    expect(regex).to be_a(Regexp)
  end

  it 'can generate sample string' do
    expect(regex.sample).to eq("foo")
  end

  it 'can generate sample string without verification' do
    expect(regex.sample(verification: false)).to eq("foo")
  end

  it 'can generate same sample strings when same seed provided' do
    expect(/\w/.sample(seed: 100)).to eq(/\w/.sample(seed: 100))
  end

  it 'can raise exception when regex cannot generate string' do
  end

  it 'can generate MatchData' do
  end

  it 'can generate string by to_json method' do
  end

  it 'can generate json string' do
  end
end
