# frozen_string_literal: true
# encoding: UTF-8

# Copyright (C) 2017-2022 MSP-Greg

require 'rbconfig' unless defined? RbConfig
require 'tmpdir'

module VersInfo

  SIGNAL_LIST = Signal.list.keys.sort

  if IO === $stdout
    YELLOW = "\e[33m"
    RESET  = "\e[0m"
  else
    YELLOW = ''
    RESET  = ''
  end

  BIN_DIR = RbConfig::CONFIG['bindir']

  @@col_wid = [34, 14, 17, 26, 10, 16]

  WIN = !!RUBY_PLATFORM[/mingw|mswin/]

  # some fonts render \u2015 as a solid, other not...
  case ARGV[0]
  when 'utf-8'
    @@dash = "\u2500".dup.force_encoding 'utf-8'
  when 'Windows-1252'
    @@dash = 151.chr
  else
    @@dash = "\u2500".dup.force_encoding 'utf-8'
  end

  class << self

    def run

      highlight "\n#{RUBY_DESCRIPTION}"
      puts
      puts "RUBY_ENGINE:         #{defined?(RUBY_ENGINE) ? RUBY_ENGINE : 'nil'}"
      puts "RUBY_ENGINE_VERSION: #{defined?(RUBY_ENGINE_VERSION) ? RUBY_ENGINE_VERSION : 'nil'}"
      puts "RUBY_PLATFORM:       #{RUBY_PLATFORM}", ''
      puts " Build Type/Info: #{ri2_vers}" if WIN
      if (gcc = RbConfig::CONFIG["CC_VERSION_MESSAGE"])
        puts "        gcc info: #{gcc[/\A.+?\n/].strip}"
      end
      puts "RbConfig::TOPDIR: #{RbConfig::TOPDIR}"
      puts
      puts "RbConfig::CONFIG['LIBRUBY_SO']:     #{RbConfig::CONFIG['LIBRUBY_SO']}"
      puts "RbConfig::CONFIG['LIBRUBY_SONAME']: #{RbConfig::CONFIG['LIBRUBY_SONAME'] || 'nil'}"
      puts ""
      puts "Dir.tmpdir:  #{Dir.tmpdir}"
      if (t = ENV['RUNNER_TEMP'])
        puts "RUNNER_TEMP: #{t}"
      end
      puts ""

      puts "RbConfig::CONFIG['configure_args']:"
      ary = RbConfig::CONFIG['configure_args'].strip.split(/ '?--/)
        .map { |e| e =~ /\A'?--/ ? e : "--#{e}" }
        .map { |e| (e.end_with?("'") && !e.start_with?("'")) ? e.sub("--", "'--") : e }
        .map { |e| "  #{e}" }
      puts(*ary)
      puts

      first('rubygems'  , 'Gem::VERSION'    , 2)  { Gem::VERSION      }
      first('bundler'   , 'Bundler::VERSION', 2)  { Bundler::VERSION }

      puts
      first('bigdecimal', 'BigDecimal.ver', 2)  {
        BigDecimal.const_defined?(:VERSION) ? BigDecimal::VERSION : BigDecimal.ver
      }
      first('gdbm'      , 'GDBM::VERSION' , 2)  { GDBM::VERSION    }
      first('json/ext'  , 'JSON::VERSION' , 2)  { JSON::VERSION    }
      puts

      openssl_conf = ENV.delete 'OPENSSL_CONF'

      if first('openssl', 'OpenSSL::VERSION', 0) { OpenSSL::VERSION }
        additional('SSL Verify'             , 0, 4) { ssl_verify }
        additional('OPENSSL_VERSION'        , 0, 4) { OpenSSL::OPENSSL_VERSION }
        if OpenSSL.const_defined?(:OPENSSL_LIBRARY_VERSION)
          additional('OPENSSL_LIBRARY_VERSION', 0, 4) { OpenSSL::OPENSSL_LIBRARY_VERSION }
        else
          additional('OPENSSL_LIBRARY_VERSION', 0, 4) { "Not Defined" }
        end
        ssl_methods
        puts
        additional_file('X509::DEFAULT_CERT_FILE'    , 0, 4) { OpenSSL::X509::DEFAULT_CERT_FILE }
        additional_file('X509::DEFAULT_CERT_DIR'     , 0, 4) { OpenSSL::X509::DEFAULT_CERT_DIR }
        additional_file('Config::DEFAULT_CONFIG_FILE', 0, 4) { OpenSSL::Config::DEFAULT_CONFIG_FILE }
        puts
        additional_file("ENV['SSL_CERT_FILE']"       , 0, 4) { ENV['SSL_CERT_FILE'] }
        additional_file("ENV['SSL_CERT_DIR']"        , 0, 4) { ENV['SSL_CERT_DIR' ] }
        ENV['OPENSSL_CONF'] = openssl_conf if openssl_conf
        additional_file("ENV['OPENSSL_CONF']"        , 0, 4) { ENV['OPENSSL_CONF' ] }
      end
      puts

      double('psych', 'Psych::VERSION', 'LIBYAML_VERSION', 3, 1, 2) { [Psych::VERSION, Psych::LIBYAML_VERSION] }
      begin
        require 'readline'
        @rl_type = (Readline.method(:line_buffer).source_location ? 'rb' : 'so')
        first('readline', "Readline::VERSION (#{@rl_type})", 3) { Readline::VERSION }
      rescue LoadError
      end
      double('zlib', 'Zlib::VERSION', 'ZLIB_VERSION', 3, 1, 2) { [Zlib::VERSION, Zlib::ZLIB_VERSION] }

      if const_defined?(:Integer)
        puts Integer.const_defined?(:GMP_VERSION) ?
          "#{'Integer::GMP_VERSION'.ljust(@@col_wid[3])}#{Integer::GMP_VERSION}" :
          "#{'Integer::GMP_VERSION'.ljust(@@col_wid[3])}Unknown"
      elsif const_defined?(:Bignum)
        puts Bignum.const_defined?(:GMP_VERSION) ?
          "#{'Bignum::GMP_VERSION'.ljust( @@col_wid[3])}#{Bignum::GMP_VERSION}" :
          "#{'Bignum::GMP_VERSION'.ljust( @@col_wid[3])}Unknown"
      end

      puts '', "Available signals:"
      if SIGNAL_LIST.length > 13
        puts "  #{SIGNAL_LIST.select { |s| s <  'K' }.map { |s| s.ljust 7 }.join}",
             "  #{SIGNAL_LIST.select { |s| s >= 'K' && s < 'TT'}.map { |s| s.ljust 7 }.join}",
             "  #{SIGNAL_LIST.select { |s| s >= 'TT'}.map { |s| s.ljust 7 }.join}"
      else
        puts "  #{SIGNAL_LIST.map { |s| s.ljust 7 }.join}"
      end


      highlight "\n#{@@dash * 5} CLI Test #{@@dash * 17}    #{@@dash * 6} Require Test #{@@dash * 6}     #{@@dash * 5} Require Test #{@@dash * 5}"
      puts chk_cli("bundle -v",      /\ABundler version (\d{1,2}\.\d{1,2}\.\d{1,2}(\.[a-z0-9]+)?)/) +
        loads('dbm'     , 'DBM'   , 'win32/registry', 'Win32::Registry')

      puts chk_cli("gem --version",  /\A(\d{1,2}\.\d{1,2}\.\d{1,2}(\.[a-z0-9]+)?)/) +
        loads('debug'  , 'Debug'  , 'win32ole'      , 'WIN32OLE')

      puts chk_cli("irb --version",  /\Airb +(\d{1,2}\.\d{1,2}\.\d{1,2}(\.[a-z0-9]+)?)/) +
        loads('digest'  , 'Digest')
      puts chk_cli("racc --version", /\Aracc version (\d{1,2}\.\d{1,2}\.\d{1,2}(\.[a-z0-9]+)?)/) +
        loads('fiddle'  , 'Fiddle')
      puts chk_cli("rake -V", /\Arake, version (\d{1,2}\.\d{1,2}\.\d{1,2}(\.[a-z0-9]+)?)/) +
        loads('socket'  , 'Socket')
      puts chk_cli("rbs -v" , /\Arbs (\d{1,2}\.\d{1,2}\.\d{1,2}(\.[a-z0-9]+)?)/)
      puts chk_cli("rdoc -v", /\A(\d{1,2}\.\d{1,2}\.\d{1,2}(\.[a-z0-9]+)?)/)

      gem_list
      puts ''
    end

    private

    def ri2_vers
      fn = "#{RbConfig::TOPDIR}/lib/ruby/site_ruby/#{RbConfig::CONFIG['ruby_version']}/ruby_installer/runtime/package_version.rb"
      if File.exist?(fn)
        s = File.read(fn)
        "RubyInstaller2 vers #{s[/^ *PACKAGE_VERSION *= *['"]([^'"]+)/, 1].strip}  commit #{s[/^ *GIT_COMMIT *= *['"]([^'"]+)/, 1].strip}"
      elsif RUBY_PLATFORM[/mingw/]
        'RubyInstaller build?'
      else
        'NA'
      end
    end

    def loads(req1, str1, req2 = nil, str2 = nil)
      wid1 = 31
      wid2 = 15
      begin
        str = ("#{str1.ljust wid2}  " +
          ((WIN && RUBY_VERSION < '3.1' && req1 == 'debug') ? 'na' : 'Ok')).ljust wid1
      rescue LoadError
        str = "#{str1.ljust wid2}  LoadError".ljust wid1
      rescue => e
        str = "#{str1.ljust wid2}  #{e.class}".ljust wid1
      end
      if req2 && (WIN || !req2[/\Awin32/])
        begin
          require req2
          str + "#{str2.ljust wid2}  Ok"
        rescue LoadError
          str + "#{str2.ljust wid2}  LoadError"
        end
      else
        str.strip
      end
    end

    def first(req, text, idx)
      col = idx > 10 ? idx : @@col_wid[idx]
      require req
      puts "#{text.ljust(col)}#{yield}"
      true
    rescue LoadError
      puts "#{text.ljust(col)}NOT FOUND!"
      false
    end

    def additional(text, idx, indent = 0)
      fn = yield
      puts "#{(' ' * indent + text).ljust(@@col_wid[idx])}#{fn}"
    rescue LoadError
    end

    def additional_file(text, idx, indent = 0)
      fn = yield
      if fn.nil?
        found = 'No ENV key'
      else
        disp_fn = fn
        disp_fn = disp_fn.sub "#{RbConfig::TOPDIR}/", '' if fn && fn.length > 34

        if /\./ =~ File.basename(fn)
          found = File.exist?(fn) ?
            "#{File.mtime(fn).utc.strftime('File Dated %F').ljust(23)}#{disp_fn}" :
            "#{'File Not Found!'.ljust(23)}#{fn}"
        elsif Dir.exist? fn
          found = "#{'Dir  Exists'.ljust(23)}#{disp_fn}\n".dup
          unless fn == (t = File.realpath(fn))
            found << "#{' ' * @@col_wid[idx]}#{'Dir  realpath'.ljust(23)}#{t}\n"
          end
        else
          found = "#{'Dir  Not Found!'.ljust(23)}#{fn}"
        end
      end
      puts "#{(' ' * indent + text).ljust(@@col_wid[idx])}#{found}"
    rescue LoadError
    end

    def env_file_exists(env)
      if fn = ENV[env]
        if /\./ =~ File.basename(fn)
          "#{ File.exist?(fn) ? "#{File.mtime(fn).utc.strftime('File Dated %F')}" : 'File Not Found!      '}  #{fn}"
        else
          "#{(Dir.exist?(fn) ? 'Dir  Exists' : 'Dir  Not Found!').ljust(23)}  #{fn}"
        end
      else
        "none"
      end
    end

    def double(req, text1, text2, idx1, idx2, idx3)
      require req
      val1, val2 = yield
      puts "#{text1.ljust(@@col_wid[idx1])}#{val1.ljust(@@col_wid[idx2])}" \
           "#{text2.ljust(@@col_wid[idx3])}#{val2}"
    rescue LoadError
      puts "#{text1.ljust(@@col_wid[idx1])}NOT FOUND!"
    end

    def gem_list
      name_wid = 24
      ary_default = []
      ary_bundled = []

      Gem::Specification.each { |s|
        if s.spec_dir.start_with? Gem.dir
          if s.default_gem?
            ary_default << [s.name, s.version.to_s]
          else
            ary_bundled << [s.name, s.version.to_s]
          end
        end
      }
      ary_default.sort_by! { |a| a[0] }
      ary_bundled.sort_by! { |a| a[0] }

      return if ary_default.empty? && ary_bundled.empty?

      highlight "\n#{@@dash * 23} #{"Default Gems #{@@dash * 5}".ljust(name_wid)} #{@@dash * 23} Bundled Gems #{@@dash * 5}"

      max_rows = [ary_default.length || 0, ary_bundled.length || 0].max

      (0..(max_rows-1)).each { |i|
        dflt = ary_default[i] ? ary_default[i] : ["", "", 0]
        bndl = ary_bundled[i] ? ary_bundled[i] : nil

        str_dflt = "#{dflt[1].rjust(23)} #{dflt[0].ljust(name_wid)}"
        str_bndl = bndl ? "#{bndl[1].rjust(23)} #{bndl[0]}" : ''

        puts bndl ? "#{str_dflt} #{str_bndl}".rstrip : "#{str_dflt}".rstrip
      }
      puts ''
    end

    def ssl_methods
      ssl = OpenSSL::SSL
      if RUBY_VERSION < '2.0'
        additional('SSLContext::METHODS', 0, 4) {
          ssl::SSLContext::METHODS.reject { |e| /client|server/ =~ e }.sort.join(' ')
        }
      else
        require_relative 'ssl_test'
        additional('Available Protocols', 0, 4) {
          TestSSL.check_supported_protocol_versions
        }
      end
    end

    def ssl_verify
      require 'net/http'
      uri = URI.parse('https://raw.githubusercontent.com/gcc-mirror/gcc/master/config.guess')
      Net::HTTP.start(uri.host, uri.port, :use_ssl => true, :verify_mode => OpenSSL::SSL::VERIFY_PEER) { |https|
        Net::HTTP::Get.new uri
      }
      "Success"
    rescue SocketError
      "*** UNKNOWN - internet connection failure? ***"
    rescue OpenSSL::SSL::SSLError # => e
      "*** FAILURE ***"
    end

    def chk_cli(cmd, regex)
      wid = 36
      return 'rbs       na'.ljust(wid) if cmd.start_with?('rbs') && RUBY_VERSION < '3'
      cmd_str = cmd[/\A[^ ]+/].ljust(10)
      if Dir["#{cmd[/\A[^ ]+/]}*", BIN_DIR].empty?
        "#{cmd_str}na   missing binstub".ljust(wid)
      else
        require 'open3'
        ret = ''.dup
        Open3.popen3(cmd) {|stdin, stdout, stderr, wait_thr|
          ret = stdout.read.strip
        }
        ret[regex] ? "#{cmd_str}Ok   #{$1}".ljust(wid) : "#{cmd_str}No   version?".ljust(wid)
      end
    rescue
      "#{cmd_str}incorrect binstub".ljust(wid)
    end

    def highlight(str)
      str2 = str.dup
      while str2.sub!(/\A\n/, '') do ; puts ; end
      puts "#{YELLOW}#{str2}#{RESET}"
    end

  end
end

VersInfo.run
exit 0 if IO === $stdout
