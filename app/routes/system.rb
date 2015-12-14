require 'system'
require 'disk'


class ZUI < Sinatra::Application
  # system page
  get '/system' do
    @disks = Disk.all
    @os_name = System.os_name
    @os_release = System.os_release
    @platform = System.platform
    @load = System.load
    @cpuinfo = System.cpuinfo
    @meminfo = System.meminfo
    @storage_controller = System.storage_controller
    @network_interfaces = System.network_interfaces
    erb :'system/index', layout: !request.xhr?
  end
end