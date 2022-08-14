# frozen_string_literal: true

#———————————————————————————————————————————————————————————————————————————————
# Copyright 2022 MSP-Greg
# License: The MIT License (MIT)
#———————————————————————————————————————————————————————————————————————————————

require 'socket'
require 'io/wait' unless IO.public_instance_methods(false).include? :wait_readable

module SURuby

  CLOSE_STR = "\0\eclose"

  DEBUG = ENV['SUB_PROCESS_DEBUG'] == 'true'

  if DEBUG
    require_relative 'sub_process_info.rb'
  end

  class << self

    def run
      @server = TCPServer.new ARGV[0], ARGV[1].to_i
      # @server = TCPServer.new '127.0.0.1', 50_000
      @client = @server.accept

      # close if parse_msg returns true
      while @client.wait_readable
        if parse_msg @client.sysread(20_480)
          @client.close
          @server.close
          break
        end
      end
    end
    
    def parse_msg(msg)
      return true if msg == CLOSE_STR

      if DEBUG && msg.start_with?("\0\e")
        reply = SubProcessInfo.call msg.delete("\0\e")
        @client.syswrite reply
      else
        # echo msg
        @client.syswrite msg
      end
      false
    end
  end
end
SURuby.run
