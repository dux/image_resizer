# base app class

module App
  extend self

  CONFIG = Struct.new(:url, :icon, :logger, :error_logger, :root, :secret, :quality, :clear_interval, :env).new

  CONFIG.icon           = File.read('./public/favicon.ico')
  CONFIG.root           = File.expand_path('../..', File.dirname(__FILE__))
  CONFIG.secret         = ENV.fetch('RESIZER_SECRET')
  CONFIG.quality        = ENV.fetch('QUALITY') { 95 }
  CONFIG.clear_interval = ENV.fetch('RESIZER_CACHE_CLEAR') { 2 }
  CONFIG.url            = ENV.fetch('RESIZER_SERVER')
  CONFIG.env            = ENV.fetch('RACK_ENV')

  CONFIG.logger         = Logger.new('./log/app.log', 'weekly')
  CONFIG.error_logger   = Logger.new('./log/errors.log', 'weekly')
  CONFIG.error_logger.formatter = CONFIG.logger.formatter = proc { |severity, datetime, progname, msg| "#{datetime}: #{msg}\n" }

  @last_cache_check = 0

  def config
    CONFIG
  end

  def call env
    app = new env
    app.router
    app.deliver
  end

  def dev?
    ENV.fetch('RACK_ENV') == 'development'
  end

  def log data=nil
    if dev?
      puts data
    else
      config.error_logger.info data
    end
  end

  def log_error data=nil
    if dev?
      ap [data.class, data.message, data.backtrace.first(5)]
    else
      config.error_logger.error [data.class, data.message].join(' - ')
      config.error_logger.error data.backtrace.first(5).join($/) if data.is_a?(StandardError)
    end
  end

  def die text
    log.error text
    puts text.red
    exit
  end

  def clear_cache
    # check every hour
    if (@last_cache_check + 3600) < Time.now.to_i
      @last_cache_check = Time.now.to_i
      clear_cache_do
    end
  end

  def clear_cache_do
    base = "find ./cache -depth -type f -atime #{config.clear_interval}"
    count = `#{base} | wc -l`.chomp.to_i

    if count > 0
      Thread.new { system "#{base} -delete" }

      log 'CLEARED %d file/s from cache dirs, older than %s days' % [count, config.clear_interval]
    end
  end

  def filesize size
    size = size.to_f

    {
      'B'  => 1024,
      'KB' => 1024 * 1024,
      'MB' => 1024 * 1024 * 1024,
      'GB' => 1024 * 1024 * 1024 * 1024,
      'TB' => 1024 * 1024 * 1024 * 1024 * 1024
    }.each_pair do |e, s|
      return "#{(size / (s / 1024)).round(['B'].include?(e) ? 0 : 2)} #{e}" if size < s
    end
  end
end
