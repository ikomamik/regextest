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

  it 'can generate array of sample strings' do
    expect(regex.samples(2)).to eq(["foo", "foo"])
  end

  it 'can generate array of sample strings without verification' do
    expect(regex.samples(2, verification: false)).to eq(["foo", "foo"])
  end

  it 'can generate same sample strings sequence when same seed provided' do
    expect(/\w/.samples(100, seed: 100)).to eq(/\w/.samples(100, seed: 100))
  end

  it 'can generate array of MatchData' do
    expect(regex.match_data(2)[1].to_s).to eq("foo")
  end
end
