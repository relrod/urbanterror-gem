#!/usr/bin/env ruby

require 'socket'
require 'pp'

class UrbanTerror
  def initialize(server, port=nil, rcon=nil)
    @server = server
    @port = port || 27960
    @rcon = rcon || ''
    @socket = UDPSocket.open
  end

  def send_command(command)
    magic = "\377\377\377\377"
    @socket.send("#{magic}#{command}\n", 0, @server, @port)
    @socket.recv(2048)
  end

  def get(command)
    send_command("get#{command}")
  end

  def rcon(command)
    send_command("rcon #{@rcon} #{command}")
  end

  # settings() returns a hash of settings => values.
  # We /were/ going to accept an optional setting arg, but it would be
  # doing the same thing and just selecting one from the Hash, so
  # why not just let the user do server.settings['map'] or whatever.
  def settings
    result = get_parts("status", 1).split("\\").reject(&:empty?)
    Hash[*result]
  end
  
  # players() returns a list of hashes. Each hash contains
  # name, score, ping.
  def players
    results = get_parts("status", 2..-1)
    results.map do |player|
      player = player.split(" ", 3)
      {
        :name => player[2][1..-2],
        :ping => player[1].to_i,
        :score => player[0].to_i
      }
    end
  end
  
  GEAR_TYPES = {
    'knives'   => 0,
    'grenades' => 1,
    'snipers'  => 2,
    'spas'     => 4,
    'pistols'  => 8,
    'autos'    => 16,
    'negev'    => 32
  }

  MAX_GEAR = 63
  
  def self.gear_calc(gear_array)
    gear_array.each{ |w| raise "No such gear type '#{w}'" unless GEAR_TYPES.has_key?(w) }
    MAX_GEAR - gear_array.map{|w| GEAR_TYPES[w] }.reduce(:+)
  end
  
  def self.reverse_gear_calc(number)
    raise "#{number} is outside of the range 0 to 63." unless (0..63).include?(number)
    GEAR_TYPES.select{|weapon, gear_val| number & gear_val == 0 }.map(&:first)
  end

  GAME_MODES = {
    0 => ['Free For All',      'FFA'],
    1 => ['Last Man Standing', 'LMS'],
    3 => ['Team Death Match',  'TDM'],
    4 => ['Team Survivor',     'TS'],
    5 => ['Follow the Leader', 'FTL'],
    6 => ['Capture and Hold',  'CAH'],
    7 => ['Capture the Flag',  'CTF'],
    8 => ['Bomb mode',         'BOMB'],
    9 => ['Jump mode',         'JUMP'],
    10 => ['Freeze Tag',       'FREEZE']
  }
  
  def self.match_type(number, abbreviate=false)
    raise "#{number} is not a valid gametype." unless GAME_MODES.has_key? number
    GAME_MODES[number][abbreviate ? 1 : 0]
  end  

  private
  def get_parts(command, i)
    get(command).split("\n")[i]
  end
end
