#!/usr/bin/env ruby
#
# bc-tohtml.rb
#
# Copyright (c) 2006-2007 Minero Aoki
#
# This program is free software.
# You can distribute/modify this program under the Ruby License.
#

require 'pathname'

def srcdir_root
  (Pathname.new(__FILE__).realpath.dirname + '..').cleanpath
end

$LOAD_PATH.unshift srcdir_root() + 'lib'

$KCODE = 'EUC'

require 'bitclust'
require 'optparse'

def main
  templatedir = srcdir_root() + 'template.offline'
  target = nil
  baseurl = '.'
  parser = OptionParser.new
  parser.banner = "Usage: #{File.basename($0, '.*')} rdfile"
  parser.on('--target=NAME', 'Compile NAME to HTML.') {|name|
    target = name
  }
  parser.on('--baseurl=URL', 'Base URL of generated HTML') {|url|
    baseurl = url
  }
  parser.on('--templatedir=PATH', 'Template directory') {|path|
    templatedir = path
  }
  parser.on('--help', 'Prints this message and quit.') {
    puts parser.help
    exit 0
  }
  begin
    parser.parse!
  rescue OptionParser::ParseError => err
    $stderr.puts err.message
    $stderr.puts parser.help
    exit 1
  end
  if ARGV.size > 1
    $stderr.puts "too many arguments (expected 1)"
    exit 1
  end

  lib = BitClust::RRDParser.parse_stdlib_file(ARGV[0])
  entry = target ? lookup(lib, target) : lib
  manager = BitClust::ScreenManager.new(
    :templatedir => templatedir,
    :base_url => baseurl,
    :cgi_url => baseurl,
    :default_encoding => 'euc-jp')
  puts manager.entry_screen(entry).body
rescue BitClust::WriterError => err
  $stderr.puts err.message
  exit 1
end

def lookup(lib, key)
  case
  when BitClust::NameUtils.method_spec?(key)
    spec = BitClust::MethodSpec.parse(key)
    if spec.constant?
      begin
        lib.fetch_class(key)
      rescue BitClust::UserError
        lib.fetch_methods(spec)
      end
    else
      lib.fetch_methods(spec)
    end
  when BitClust::NameUtils.classname?(key)
    lib.fetch_class(key)
  else
    raise BitClust::InvalidKey, "wrong search key: #{key.inspect}"
  end
end

main