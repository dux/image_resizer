require 'spec_helper'
require './app/routes/helper'

describe 'rack image resizer' do
  it 'encodes strings' do
    string = 'https://foobar'

    enc = RackImageResizer.encode string
    dec = RackImageResizer.decode enc

    expect(string).to eq(dec)
  end

  it 'encodes hashes' do
    hash = { foo: 'bar', baz: true }

    enc = RackImageResizer.encode hash
    dec = RackImageResizer.decode enc

    expect(hash).to eq(dec)
  end
end

