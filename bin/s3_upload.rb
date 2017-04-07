#!/usr/bin/env ruby

# bin/s3_upload [source - path to file] [target - bucket/path]
# bin/s3_upload ./log/test.log klarx-assets/db-backups

require 'aws-sdk'
require 'json'
require 'dotenv'

# load AWS_KEY, AWS_SECRET and AWS_REGION from env
Dotenv.load

Aws.config.update({
  region: ENV['AWS_REGION'],
  credentials: Aws::Credentials.new(ENV['AWS_KEY'], ENV['AWS_SECRET'])
})

unless ARGV[1]
  puts "bin/s3_upload [source - path to file] [target - bucket/path]"

  # list buckets
  puts "buckets:"
  s3c = Aws::S3::Client.new
  puts s3c.list_buckets.buckets.map(&:name)

  exit
end

source = ARGV[0]
unless File.exists?(source)
  puts "File #{source} not found"
  exit
end

bucket, target = ARGV[1].split('/', 2)

file = source.split('/').reverse[0]
target.sub!(/\/$/,'')

s3r  = Aws::S3::Resource.new

meta = {}
meta['content-type'] = "image/#{source.split('.').last}"
meta['etag'] = Digest::MD5.hexdigest File.read source
meta['cache-control'] = "max-age=#{60*60*24*365}"

bucket = s3r.bucket(bucket)
bucket.object(target).upload_file(source, { metadata: meta, acl: 'public-read' })

