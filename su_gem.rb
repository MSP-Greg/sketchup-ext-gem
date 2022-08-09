# frozen_string_literal: true
# Copyright 2022 MSP-Greg

=begin

Run either with a full command string
  SUGem.run "install <gem list or path> --no-user-install -N"

Or by using using gem command as method
  SUGem.env
  SUGem.install '<gem list or path> --no-user-install -N'
  SUGem.uninstall '<gem list>'
  SUGem.query '<gem list> -d'
  SUGem.query '-d'
  SUGem.outdated

=end

module SUGem

  class << self

  def run args
    returned = false

    # load here so only loaded when run
    require 'stringio'
    require 'rubygems'
    require 'rubygems/command_manager'
    require 'rubygems/config_file'
    require 'rubygems/deprecate'

    ary_args = args.split(/ +/)

    cmd = Gem::CommandManager.instance
    # fix abbreviation
    ary_args[0] = 'environment' if ary_args[0] =~ /\Aenv\Z/i
    unless cmd.command_names.include? ary_args[0]
      puts 'SUGem - Invalid gem command!'
      returned = true
      return
    end

    build_args = extract_build_args ary_args

    do_configuration ary_args

    cmd.command_names.each do |command_name|
      config_args = Gem.configuration[command_name]
      config_args = case config_args
                    when String
                      config_args.split ' '
                    else
                      Array config_args
                    end
      Gem::Command.add_specific_extra_args command_name, config_args
    end
    #sio_in, @io_in = IO.pipe
#    @sio_in = nil
    sio_in, sio_out, sio_err = StringIO.new, StringIO.new, StringIO.new
    cmd.ui = Gem::StreamUI.new sio_in, sio_out, sio_err, false

    cmd.run Gem.configuration.args, build_args
    t = sio_err.string
    puts "err #{t}\n" unless t.empty?
  rescue Gem::SystemExitException => e
    t = e.message
    puts t unless t.end_with? 'exit_code 0'
    t = sio_err.string
    puts t unless t.empty?
  ensure
    return if returned
    t = sio_out ? sio_out.string : ''
    puts t unless t.empty?

    sio_in  and sio_in.close
    sio_out and sio_out.close
    sio_err and sio_err.close
  end

  private

  def extract_build_args args # :nodoc:
    return [] unless offset = args.index('--')
    build_args = args.slice!(offset...args.length)
    build_args.shift
    build_args
  end

  def do_configuration(args)
    Gem.configuration = Gem::ConfigFile.new args
    Gem.use_paths Gem.configuration[:gemhome], Gem.configuration[:gempath]
    Gem::Command.extra_args = Gem.configuration[:gem]
  end

  def method_missing(meth, arg = '')
    raise ArgumentError('SUGem - argument must be a string') unless String === arg
    arg =  "#{meth} #{arg}"
    run arg
  end

  end # class << self
end
