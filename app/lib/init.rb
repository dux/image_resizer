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

# delete all cache files which where not accessd in 2 days
`find ./cache -depth -type f -atime +2 -delete`