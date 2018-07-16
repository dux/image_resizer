# base app class

module App
  extend self

  ICON     = File.read('./public/favicon.ico')
  LOG_FILE = ENV.fetch('RACK_ENV') == 'development' ? STDOUT : './log/production.log'
  LOGGER   = Logger.new(LOG_FILE, 'weekly')
  ROOT     = File.expand_path('..', File.dirname(__FILE__))

  LOGGER.datetime_format = '%F %R'

  def call env
    app = new env
    app.router
    app.deliver
  end

  def log data=nil
    if data
      puts data.yellow if App.is_local?
    else
      LOGGER
    end
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
