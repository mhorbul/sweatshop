require 'rubygems'
require 'mq'
require 'digest'
require 'yaml'

$:.unshift(File.dirname(__FILE__))
require 'sweat_shop/worker'

module SweatShop
  extend self

  def workers
    @workers ||= []
  end

  def workers=(workers)
    @workers = workers 
  end

  def complete_tasks(workers)
    EM.run do
      workers.each do |worker|
        worker.complete_tasks
      end
    end
  end

  def workers_in_group(groups)
    groups = [groups] unless groups.is_a?(Array)
    if groups.include?(:all)
      workers
    else
      workers.select do |worker|
        groups.include?(worker.queue_group)
      end
    end
  end

  def complete_all_tasks
    complete_tasks(
      workers_in_group(:all)
    )
  end

  def complete_default_tasks
    complete_tasks(
      workers_in_group(:default)
    )
  end

  def config
    @config ||= begin
      defaults = YAML.load_file(File.dirname(__FILE__) + '/../config/defaults.yml')
      if defined?(RAILS_ROOT)
        file = RAILS_ROOT + '/config/sweatshop.yml'
        if File.exist?(file)
          YAML.load_file(file)[RAILS_ENV || 'development']
        else
          defaults['enable'] = false
          defaults
        end
      else
        defaults
      end
    end
  end

  def daemonize
    require File.dirname(__FILE__) + '/sweat_shop/sweatd'
  end
end

if defined?(RAILS_ROOT)
  Dir.glob(RAILS_ROOT + '/app/workers/*.rb').each{|worker| require worker }
end