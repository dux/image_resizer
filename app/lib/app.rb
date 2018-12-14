# base app class

module App
  extend self

  ICON           = File.read('./public/favicon.ico')
  LOG_FILE       = ENV.fetch('RACK_ENV') == 'development' ? STDOUT : './log/production.log'
  LOGGER         = Logger.new(LOG_FILE, 'weekly')
  ROOT           = File.expand_path('../..', File.dirname(__FILE__))
  SECRET         = ENV.fetch('RESIZER_SECRET')
  QUALITY        = ENV.fetch('QUALITY') { 90 }
  CLEAR_INTERVAL = ENV.fetch('RESIZER_CACHE_CLEAR') { 2 }

  LOGGER.formatter = proc { |severity, datetime, progname, msg| "#{datetime}: #{msg}\n" }

  @last_cache_check = 0

  def call env
    app = new env
    app.router
    app.deliver
  end

  def log data=nil
    if data
      LOGGER.info data
    else
      LOGGER
    end
  end

  def dev_log data
    puts data.blue if App.is_local?
  end

  def is_local?
    ENV.fetch('RACK_ENV') == 'development'
  end

  def root
    ROOT
  end

  def die text
    log.error text
    puts text.red
    exit
  end

  def error msg
    puts 'Error: %s' % msg.red
    App.log.error msg
    msg
  end

  def clear_cache
    # check every hour
    if (@last_cache_check + 3600) < Time.now.to_i
      @last_cache_check = Time.now.to_i
      clear_cache_do
    end
  end

  def clear_cache_do
    base = "find ./cache -depth -type f -atime #{CLEAR_INTERVAL}"
    count = `#{base} | wc -l`.chomp.to_i

    if count > 0
      Thread.new { system "#{base} -delete" }

      log 'CLEARED %d file/s from cache dirs, older than %s days' % [files, interval]
    end
  end
end
