# base app class

module App
  extend self

  ICON     = File.read('./public/favicon.ico')
  LOG_FILE = ENV.fetch('RACK_ENV') == 'development' ? STDOUT : './log/production.log'
  LOGGER   = Logger.new(LOG_FILE, 'weekly')
  ROOT     = File.expand_path('../..', File.dirname(__FILE__))
  SECRET   = ENV.fetch('RESIZER_SECRET')

  LOGGER.formatter = proc { |severity, datetime, progname, msg| "#{datetime}: #{msg}\n" }

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
end
