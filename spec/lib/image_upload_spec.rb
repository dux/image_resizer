require 'spec_helper'
require './app/routes/helper'

# AWS_ACCESS_KEY_ID=foo
# AWS_SECRET_ACCESS_KEY=bar
# AWS_REGION=eu-central-1
# AWS_BUCKET=imagos

describe 'rack image resizer' do
  send ENV['AWS_ACCESS_KEY_ID'] ? :it : :xit, 'uploads image' do
    s3    = AwsS3Asset.new source: './public/error.png'
    image = s3.upload.split('/').last
    expect(image).to eq('13fdf8760c96775240c29045a0cd880d9ec34c3d.png')
  end
end
