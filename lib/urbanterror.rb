#!/usr/bin/env ruby

require 'socket'
require 'pp'

class UrbanTerror
  def initialize(server, port=nil, rcon=nil)
    @server = server
    @port = port.nil? ? 27960 : port
    @rcon = rcon.nil? ? '' : rcon
    @socket = UDPSocket.open
  end

  def sendCommand(command)
    magic = "\377\377\377\377"
    @socket.send("#{magic}#{command}\n", 0, @server, @port)
    @socket.recv(2048)
  end

  def get(command)
    sendCommand("get#{command}")
  end

  def getparts(command, i)
    get(command).split("\n")[i]
  end
  
  def rcon(command)
    sendCommand("rcon #{@rcon} #{command}")
  end

  # settings() returns a hash of settings => values.
  # We /were/ going to accept an optional setting arg, but it would be
  # doing the same thing and just selecting one from the Hash, so
  # why not just let the user do server.settings['map'] or whatever.
  def settings
    result = getparts("status", 1).split("\\").reject(&:empty?)
    Hash[*result]
  end
  
  # players() returns a list of hashes. Each hash contains
  # name, score, ping.
  def players
    results = getparts("status", 2..-1)
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
    'grenades' => 1,
    'snipers'  => 2,
    'spas'     => 4,
    'pistols'  => 8,
    'autos'    => 16,
    'negev'    => 32
  }

  MAX_GEAR = 63
  
  def self.gearCalc(gearArray)
    MAX_GEAR - gearArray.select{|w| GEAR_TYPES.has_key? w }.map{|w| GEAR_TYPES[w] }.reduce(:+)
  end
  
  def self.reverseGearCalc(number)
    GEAR_TYPES.select{|weapon, gear_val| number & gear_val == 0 }.map(&:first)
  end

  GAME_MODES = {
    0 => ['Free For All',      'FFA'],
    3 => ['Team Death Match',  'TDM'],
    4 => ['Team Survivor',     'TS'],
    5 => ['Follow the Leader', 'FTL'],
    6 => ['Capture and Hold',  'CAH'],
    7 => ['Capture the Flag',  'CTF'],
    8 => ['Bomb mode',         'BOMB']
  }
  
  def self.matchType(number, abbreviate=false)
    raise "#{number} is not a valid gametype." unless GAME_MODES.has_key? number
    match[number][abbreviate ? 1 : 0]
  end  
end
