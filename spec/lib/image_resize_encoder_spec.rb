require 'spec_helper'

describe 'image resizer' do

  let(:params) {
    {
      image: 'http://i.imgur.com/krurDGE.jpg',
      size: '200x200'
    }
  }

  let(:url) { params[:image].resize_image(params[:size]) }

  [:jpegoptim, :curl, :convert, :pngquant].each do |app|
    it 'shoud find %s' % app do
      expect(`which #{app}`.length > 1).to eq(true)
    end
  end

  ###

  def get_resize_base size
    img     = ImageResizer.new image: params[:image], quality: 80, reload: true, size: size
    resized = img.resize

    expect(File.exists?(resized)).to eq(true)

    info = `identify #{resized}`.split(' ')
    info[2].split('x').map(&:to_i)
  end

  ###

  it 'shoud generate pack url' do
    expect(url.length).to eq(102)
  end

  it 'shoud unpack url' do
    base = url.split('/r/').last
    opts = unpack_url(base)
    expect(opts[:s]).to eq(params[:size])
  end

  it 'shoud resize image width' do
    width, _ = get_resize_base 100

    expect(width).to eq 100
  end

  it 'shoud resize image height' do
    _, height = get_resize_base 'x100'

    expect(height).to eq 100
  end

  it 'shoud resize to fit' do
    width, height = get_resize_base '100x100'

    expect(width).to eq 56
    expect(height).to eq 100
  end

  it 'shoud resize crop' do
    width, height = get_resize_base '^100x100'

    expect(width).to eq 100
    expect(height).to eq 100
  end

  puts 'WEBP encoder https://github.com/le0pard/webp-ffi'

  if `which apt-get`.to_s == ''
    for lib in %w{libjpg libpng libtiff webp}
      it "shoud have brew lib #{lib}" do
        system 'brew install #{lib}' if `brew list #{lib}`.include?('Error:')
        expect(`brew list #{lib}`.include?('Error:')).to eq false
      end
    end
  else
    system 'sudo apt-get install libjpeg-dev libpng-dev libtiff-dev libwebp-dev'
  end
end

