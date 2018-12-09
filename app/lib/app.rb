# base app class

module App
  extend self

  ICON     = File.read('./public/favicon.ico')
  LOG_FILE = ENV.fetch('RACK_ENV') == 'development' ? STDOUT : './log/production.log'
  LOGGER   = Logger.new(LOG_FILE, 'weekly')
  ROOT     = File.expand_path('../..', File.dirname(__FILE__))
  SECRET   = ENV.fetch('RESIZER_SECRET')
  QUALITY  = ENV.fetch('QUALITY') { 90 }

  LOGGER.formatter = proc { |severity, datetime, progname, msg| "#{datetime}: #{msg}\n" }

  @@last_cache_check = 0

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
    if (@@last_cache_check + 11) < Time.now.to_i
      @@last_cache_check = Time.now.to_i
      clear_cache_do
    end
  end

  def clear_cache_do
    interval = ENV['RESIZER_CACHE_CLEAR']
    base     = "find ./cache -depth -type f -atime +#{interval}"

    dev_log base

    files = `#{base}`.split($/).length

    if files > 0
      `#{base} -delete`
      log 'CLEARED %d file/s from cache dirs with formula +%s' % [files, interval]
    end
  end
end
