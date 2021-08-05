require 'spec_helper'
require './app/routes/helper'

# AWS_ACCESS_KEY_ID=foo
# AWS_SECRET_ACCESS_KEY=bar
# AWS_REGION=eu-central-1
# AWS_BUCKET=imagos

describe AwsS3Asset do
  send ENV['AWS_ACCESS_KEY_ID'] ? :it : :xit, 'uploads image' do
    s3    = AwsS3Asset.new source: './public/error.png'
    image = s3.upload.split('/').last
    expect(image).to eq('e3287d221ce8b9d6e186cba1b81d26da77ab3233--200x200.png')
  end

  it 'generate image hash' do
    # https://blurha.sh/
    s3 = AwsS3Asset.new source: './public/flowers.jpeg'
    expect(s3.image_blur_hash).to eq('TERHQG9IK2gxaEJTT1l4V05JUio1VFN3RTJ3Sw')
  end
end
