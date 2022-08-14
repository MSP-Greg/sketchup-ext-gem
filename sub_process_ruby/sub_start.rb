# frozen_string_literal: true

#———————————————————————————————————————————————————————————————————————————————
# Copyright 2022 MSP-Greg
# License: The MIT License (MIT)
#———————————————————————————————————————————————————————————————————————————————

require 'socket'
require 'io/wait' unless IO.public_instance_methods(false).include? :wait_readable

class TCPSendRecv
  #HOST = '127.0.0.1'
  HOST =  '::1'
  CLOSE_STR = "\0\eclose"

  DEBUG = ENV['SUB_PROCESS_DEBUG'] == 'true'

  IS_WINDOWS = !!(/mingw|mswin/ =~ RUBY_PLATFORM)

  class MyAppObserver < Sketchup::AppObserver
    def initialize(io, skt)
      @io, @skt = io, skt
      super()
    end
    
    def onQuit
      if @skt.is_a?(IO) && !@skt.closed?
        @skt.close
        # File.write "#{__dir__}/0_skt.txt", "@skt closed\n@io.class #{@io.class}\n@io.pid #{@io.pid}"
      end
      if @io.is_a?(IO) && (pid = @io.pid)
        Process.kill 'SIGKILL', pid
        # File.write "#{__dir__}/0_io.txt", 'closed'
      end
    rescue e
    end
  end

  def initialize
    require_relative 'sub_process_info' if DEBUG

    port = TCPServer.open(HOST, 0) { |svr| svr.connect_address.ip_port }

    env_ruby = ENV['SUB_PROCESS_RUBY']

    ruby = if env_ruby && (File.executable?(env_ruby) || File.executable?("#{env_ruby}.exe"))
      env_ruby
    else
      IS_WINDOWS ? 'rubyw' : 'ruby'
    end

    @io = IO.popen fixup_env, [ruby, "#{__dir__}/sub_process_app.rb", HOST, port.to_s]

    sleep 1

    debug_puts "Started TCPServer at #{HOST}:#{port}"
    @skt = TCPSocket.new HOST, port
    debug_puts 'Connected'
    Sketchup.add_observer MyAppObserver.new @io, @skt
  end

  def send(msg)
    @skt.syswrite msg
    debug_puts "Sent data: #{msg}"
    @skt.wait_readable
    reply = @skt.sysread 20_480
    debug_puts "Reply:\n#{reply}"
    reply
  end
  
  def close
    @skt.write CLOSE_STR
    sleep 0.5
    @skt.close
    @skt = nil
  end

  def fixup_env
    path_name = IS_WINDOWS ? 'Path' : 'PATH'
    bad_env_keys = %w[GEM_HOME GEM_PATH SSL_CERT_FILE]
    env = {}
    bad_env_keys.each { |k| env[k] = nil }
    # remove SketchUp entries
    su_path_ary = ENV[path_name].split File::PATH_SEPARATOR
    su_path_ary.reject! { |p| p.include? 'SketchUp' }
    env[path_name] = su_path_ary.join File::PATH_SEPARATOR
    env
  end

  def debug_puts(msg)
    puts msg if DEBUG
  end

  if DEBUG
    %i[env gems lf lp].each do |meth|
      define_method(meth) do
        send "\0\e#{meth}"
        nil
      end
    end
  end
end

# Sub Process Ruby
SPR = TCPSendRecv.new
