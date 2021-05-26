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
    expect(image).to eq('ebd30eb4a1e9de719501d95ffee3932d6a5af0d9.png')
  end
end
