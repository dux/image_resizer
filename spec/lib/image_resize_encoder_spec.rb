require 'spec_helper'

describe 'image resizer' do

  let(:params) {
    {
      image: 'http://i.imgur.com/krurDGE.jpg',
      crop: 200,
      secret: ENV.fetch('RESIZER_SECRET')
    }
  }

  it 'shoud generate pack url' do
    url = ImageResizerEncoder.pack(params)
    expect(url.length > 50).to eq(true)
  end

  it 'shoud resize image' do
    img     = ImageResizerImage.new image: params[:image], quality: 80, reload: true
    resized = img.resize_width(100)

    expect(File.exists?(resized)).to eq(true)

    info = `identify #{resized}`.split(' ')
    size = info[3].split('x').first.to_i

    expect(size).to eq 100
  end
end

