require 'spec_helper'

describe 'image resizer' do

  let(:params) {
    {
      image: 'http%3A//i.imgur.com/krurDGE.jpg',
      crop: 200,
      secret: ENV.fetch('RESIZER_SECRET')
    }
  }

  it 'shoud generate pack url' do
    url = ImageResizerEncoder.pack(params)
    expect(url).to eq('eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpbWFnZSI6Imh0dHAlM0EvL2kuaW1ndXIuY29tL2tydXJER0UuanBnIiwiY3JvcCI6MjAwLCJzZWNyZXQiOiJzZWNyZXQifQ.VLckUvwcSmO-j7hbz_-wy9TO8QPGlYu9UlP_bdkOVD4')
  end

  it 'shoud resize image' do

  end
end

