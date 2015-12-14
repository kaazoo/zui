require 'json'
require 'open3'


class System

  def self.os_name
    cmd = "uname -o"
    stdout, stderr, status = Open3.capture3(cmd)
    if not status.success?
      raise StandardError, "Could not retrieve OS information: #{stderr}"
    end
    return stdout
  end

  def self.os_release
    cmd = "uname -r"
    stdout, stderr, status = Open3.capture3(cmd)
    if not status.success?
      raise StandardError, "Could not retrieve OS information: #{stderr}"
    end
    return stdout
  end

  def self.platform
    cmd = "uname -i"
    stdout, stderr, status = Open3.capture3(cmd)
    if not status.success?
      raise StandardError, "Could not retrieve OS information: #{stderr}"
    end
    return stdout
  end

  def self.load
    cmd = "uptime | cut -d ' ' -f 12,13,14"
    stdout, stderr, status = Open3.capture3(cmd)
    if not status.success?
      raise StandardError, "Could not retrieve load information: #{stderr}"
    end
    return stdout
  end

  def self.cpuinfo
    cmd = "cat /proc/cpuinfo | grep 'model name' | wc -l"
    stdout, stderr, status = Open3.capture3(cmd)
    if not status.success?
      raise StandardError, "Could not retrieve CPU information: #{stderr}"
    end
    cpuinfo = stdout.split("\n")[0] + "x "
    cmd = "cat /proc/cpuinfo | grep 'model name' | uniq | cut -d ':' -f 2"
    stdout, stderr, status = Open3.capture3(cmd)
    if not status.success?
      raise StandardError, "Could not retrieve CPU information: #{stderr}"
    end
    cpuinfo += stdout.lstrip.split("\n")[0]
    return cpuinfo
  end

  def self.meminfo
    cmd = "free -h | grep Mem | awk '{print $2}'"
    stdout, stderr, status = Open3.capture3(cmd)
    if not status.success?
      raise StandardError, "Could not retrieve memory information: #{stderr}"
    end
    meminfo = stdout.split("\n")[0] + " total / "
    cmd = "free -h | grep 'buffers/cache' | awk '{print $3}'"
    stdout, stderr, status = Open3.capture3(cmd)
    if not status.success?
      raise StandardError, "Could not retrieve memory information: #{stderr}"
    end
    meminfo += (stdout.split("\n")[0] + " used")
    return meminfo
  end

  def self.storage_controller
    cmd = "lspci | grep -i storage | cut -d ':' -f 3 | sed ':a;N;$!ba;s/\\n/\\<br\\>/g'"
    stdout, stderr, status = Open3.capture3(cmd)
    if not status.success?
      raise StandardError, "Could not retrieve controller information: #{stderr}"
    end
    return stdout
  end

  def self.network_interfaces
    interfaces = []
    dirbase = '/sys/class/net'
    Dir.chdir(dirbase)
    Dir.glob('*').select {|iface|
      if iface != 'lo'
        iface_info = {}
        iface_info[:name] = iface
        iface_info[:address] = IO.readlines(File.join(dirbase, iface, 'address'))[0].split("\n")[0]
        iface_info[:duplex] = IO.readlines(File.join(dirbase, iface, 'duplex'))[0].split("\n")[0] rescue 'none'
        iface_info[:mtu] = IO.readlines(File.join(dirbase, iface, 'mtu'))[0].split("\n")[0]
        iface_info[:operstate] = IO.readlines(File.join(dirbase, iface, 'operstate'))[0].split("\n")[0]
        iface_info[:speed] = IO.readlines(File.join(dirbase, iface, 'speed'))[0].split("\n")[0] rescue 'none'
        IO.readlines(File.join(dirbase, iface, 'device/uevent')).each do |line|
          if line.include?('DRIVER')
            iface_info[:driver] = line.split('=')[1].split("\n")[0]
          end
          if line.include?('PCI_SLOT_NAME')
            iface_info[:pci_slot] = line.split('=')[1].gsub('0000:','').split("\n")[0]
          end
        end
        cmd = "lspci | grep " + iface_info[:pci_slot] + " | cut -d ':' -f 3"
        stdout, stderr, status = Open3.capture3(cmd)
        if not status.success?
          raise StandardError, "Could not retrieve controller information: #{stderr}"
        end
        iface_info[:controller] = stdout.lstrip.split("\n")[0]
        cmd = "ip addr show " + iface + " | grep 'inet ' | awk '{print $2}'"
        stdout, stderr, status = Open3.capture3(cmd)
        if not status.success?
          raise StandardError, "Could not retrieve controller information: #{stderr}"
        end
        if stdout == ""
          iface_info[:ipv4] = "none"
        else
          iface_info[:ipv4] = stdout.lstrip.split("\n")[0]
        end
        cmd = "ip addr show " + iface + " | grep 'inet6' | awk '{print $2}'"
        stdout, stderr, status = Open3.capture3(cmd)
        if not status.success?
          raise StandardError, "Could not retrieve controller information: #{stderr}"
        end
        if stdout == ""
          iface_info[:ipv6] = "none"
        else
          iface_info[:ipv6] = stdout.lstrip.split("\n")[0]
        end
        interfaces << iface_info
      end
    }
    return interfaces
  end


end

