puts "...loading Locomotive engine"

require 'rails'
require 'json/pure'
require 'devise'
require 'mongoid'
require 'mongoid_acts_as_tree'
require 'will_paginate'
require 'haml'
require 'liquid'
require 'formtastic'
require 'inherited_resources'
require 'carrierwave'
require 'custom_fields'
require 'mimetype_fu'
require 'actionmailer_with_request'
require 'heroku'
require 'bushido'
require 'httparty'
require 'redcloth'
require 'delayed_job_mongoid'
require 'zip/zipfilesystem'
require 'jammit-s3'
require 'dragonfly'
require 'cancan'
require 'RMagick'
require 'cells'
require 'sanitize'

require 'rack/raw_upload'
require 'compass/logger'
require 'ninesixty'

$:.unshift File.dirname(__FILE__)

module Locomotive
  class Engine < Rails::Engine

    config.autoload_once_paths += %W( #{config.root}/app/controllers #{config.root}/app/models #{config.root}/app/helpers #{config.root}/app/uploaders)

    initializer "locomotive.cells" do |app|
      Cell::Base.prepend_view_path("#{config.root}/app/cells")
    end
    
    initializer "accepting HTML5 drag & drop uploads" do |app|
      app.middleware.use Rack::RawUpload#, :paths => ['/admin/asset_collections.*']
    end
    
    initializer "serving files from mongo gridfs" do |app|
      require 'grifizoid'
      
      app.middleware.insert_after Rack::Runtime, Grifizoid do |req|
        site      = Site.match_domain(req.host).first
        # Rails.logger.info "[running subdomain GFS lookup]: #{site.to_param} | #{req.path_info}"

        gfs_path  = File.join(site.to_param, req.path_info)
      end
    end

    rake_tasks do
      load "railties/tasks.rake"
    end

  end
end
