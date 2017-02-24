require 'spec_helper'

describe 'image resizer' do

  it 'shoud resize image' do
    img = ImageResizerImage.new('http://i.imgur.com/krurDGE.jpg', 80)
    file = img.resize_width(200)
    expect(file.include?('cache/resized/w_200-q80-a1/b8178038634bba4b93c53f7bec86ae.jpg')).to eq true
    expect(File.exists?(file)).to eq true
  end

end

