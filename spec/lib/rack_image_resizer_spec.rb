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

  it 'generates image upload url' do
    path = RackImageResizer.upload_path.split('?').first.split('/').last
    time = RackImageResizer.decode path
    expect(time[:time].to_i).to eq(Time.now.to_i)
  end

  it 'generates domain image path' do
    path = RackImageResizer.ico_path 'google.com'
    expect(path).to eq('http://localhost:4000/ico/Z29vZ2xlLmNvbQce')
  end
end

