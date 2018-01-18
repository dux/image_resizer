require 'spec_helper'

describe 'image resizer' do

  let(:params) {
    {
      image: 'http://i.imgur.com/krurDGE.jpg',
      size: '200x200'
    }
  }

  let(:url) { ImageResizerUrl.get(params) }

  it 'shoud find imagemagic convert' do
    expect(`which convert`.length > 1).to eq(true)
  end

  it 'shoud generate pack url' do
    expect(url.length).to eq(111)
  end

  it 'shoud unpack url' do
    base = url.split('/r/').last
    opts = ImageResizerUrl.unpack(base)
    expect(opts[:size]).to eq(params[:size])
  end

  it 'shoud resize image' do
    img     = ImageResizer.new image: params[:image], quality: 80, reload: true
    resized = img.resize_width(100)

    expect(File.exists?(resized)).to eq(true)

    info = `identify #{resized}`.split(' ')
    size = info[3].split('x').first.to_i

    expect(size).to eq 100
  end
end

