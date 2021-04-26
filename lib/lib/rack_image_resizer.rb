# encodes resized image URLs

require 'base64'
require 'digest'
require_relative 'string'

module ::RackImageResizer
  extend self

  @@config = Struct.new(:secret, :server).new

  def set name, value
    @@config.send '%s=' % name, value
  end

  def config
    if block_given?
      yield @@config
    else
      @@config
    end
  end

  def checksum str, length = 2
    Digest::SHA1.hexdigest(@@config.secret+str)[0, length]
  end

  def encode object
    data = []

    # add base
    data = object.is_a?(String) ? object : object.to_json
    data = Base64.urlsafe_encode64(data).gsub(/=*\s*$/, '')

    # add check, 2 chars
    data + checksum(data)
  end

  def decode string
    base, check = string.slice!(0...-2), string

    data = Base64.urlsafe_decode64(base)

    if data[0,1] == '{'
      data = JSON.load data
      data = data.inject({}) { |it, (k,v)| it[k.to_sym] = v; it }
    else
      data
    end
  end

  ###

  def resize_url opts
    opts[:p] ||= opts.delete(:proxy)
    opts[:i] ||= opts.delete(:image)
    opts[:s] ||= opts.delete(:size) || opts.delete(:w) || opts.delete(:width)
    opts[:e] ||= opts.delete(:onerror) if opts[:onerror]

    opts = opts.delete_if { |_, value| !value }

    # return empty pixel unless self
    return "data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7" if opts[:i].to_s == ''

    # optimize
    opts[:i].sub! /^http/, ''

    # raise unless is url
    raise ArgumentError.new('Invalid URL, no https?:// found') unless opts[:i] =~ %r{^s?://}

    # return full url
    [@@config.server, encode(opts)].join('/r/')
  end

  def resize_url_unpack string, params={}
    decode(string).tap do |opts|
      opts[:i] = 'http' + opts[:i]
      opts[:s] ||= params[:s]
    end
  end

  def upload_path
    '%s/upload/%s' % [@@config.server, encode(Time.now.to_i.to_s)]
  end

  def ico_path domain
    '%s/ico/%s' % [@@config.server, encode(domain)]
  end
end
