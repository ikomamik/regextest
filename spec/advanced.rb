require 'spec_helper'

describe Regextest do
  it 'can parse look-ahead and generate sample data' do
    expect(/(?=aa)./.sample).to eq("aa")
  end

  it 'can parse concurrent look-ahead and generate sample data' do
    expect(/(?=aa)(?!\w\d)./.sample).to eq("aa")
  end

  it 'can parse concurrent look-ahead and generate sample data' do
    expect(/a(?=aa)(?!\w\d)/.sample).to eq("aaa")
  end

  it 'can parse nested look-ahead and generate sample data' do
    expect(/(?=aa(?=\wa))..a/.sample).to eq("aaaa")
  end

  it 'can parse nested look-ahead/look-behind and generate sample data' do
    expect(/(?=aa(?<=\wa))..a/.sample).to eq("aaa")
  end

  it 'can parse atomic selection and generate sample data' do
    expect(/(?>ab|a|b){4}/.sample).to be_a(String)
  end

  it 'can parse atomic selection and generate sample data' do
    expect(/(?=c)(?>ab|a|c)/.sample).to be_a(String)
  end

  it 'can parse reluctant repeat and generate sample data' do
    expect(/\w{2}?\d/.sample).to match /[a-zA-Z_]{2}\d/
  end

  it 'can parse reluctant repeat and generate sample data' do
    expect(/(ab|cd){2}?bc/.sample).to be_a String
  end

  it 'can parse possessive repeat and generate sample data' do
    expect(/a++[ab]/.sample).to match /a+b/
  end

  it 'can parse possessive repeat and generate sample data' do
    expect(/[ab]++[abc]/.sample).to match /a+b/
  end

  it 'can parse look-ahead-negative + select and generate sample data' do
    expect(/(?![a-zA-Z]|[1-9])\h/.sample).to eq("0")
  end

  it 'can parse nested look-ahead-negative + select and generate sample data' do
    expect(/(?![abc]|(d|e))[a-f]/.sample).to eq("f")
  end

end
