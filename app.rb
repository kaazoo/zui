require 'rubygems'
require 'bundler'

# Setup load paths
Bundler.require
$: << File.expand_path('../', __FILE__)
$: << File.expand_path('../lib', __FILE__)

#require 'dotenv'
#Dotenv.load

#require 'active_support/core_ext/string'
#require 'active_support/core_ext/array'
#require 'active_support/core_ext/hash'
#require 'active_support/json'

libraries = Dir[File.expand_path('../lib/**/*.rb', __FILE__)]
libraries.each do |path_name|
  require path_name
end


class Zorro < Sinatra::Application
  set :root,          File.join(File.dirname(__FILE__), 'app')
  set :assets,        Sprockets::Environment.new(root)
  set :assets_prefix, '/assets'
  set :digest_assets, false

  configure do
    # Setup template engine
    set :public_folder, Proc.new { File.join(File.dirname(__FILE__), 'public') }
    set :erb, escape_html: true

    # Setup Sprockets
    %w{javascripts stylesheets images fonts}.each do |type|
      assets.append_path File.join(root, 'assets', type)
    end
    #assets.append_path File.join(root, 'assets', 'stylesheets')
    #assets.append_path File.join(root, 'assets', 'javascripts')
    #assets.append_path File.join(root, 'assets', 'images')

    # Configure Sprockets::Helpers
    Sprockets::Helpers.configure do |config|
      config.environment = assets
      config.prefix      = assets_prefix
      config.digest      = digest_assets
      config.public_path = public_folder
    end

    #Sprockets::Sass.add_sass_functions = false

    #disable :method_override
    #disable :static
  end

  #use Rack::Deflater

  helpers do
    include Sprockets::Helpers
  end
end

require_relative 'app/helpers/init'
require_relative 'app/routes/init'
