ROOT = Dir.getwd
error = nil

for dir in ['cache','cache/originals', 'cache/resized', 'cache/pages', 'cache/croped']
  dir = "#{ROOT}/#{dir}"
  Dir.mkdir(dir) unless Dir.exists?(dir)
end

def md5(data)
  ret = Digest::MD5.hexdigest data
  ret[2,0] = '/'
  ret
end
