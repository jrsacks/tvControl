#!/usr/bin/env ruby
# encoding: utf-8

require 'eventmachine'
require 'sinatra'
require 'socket'
require 'open-uri'
require 'json'
require 'date'
require 'em-http-request'

class Tivo < EventMachine::Connection
  def receive_data(data)
    puts "Tivo: #{data}"
  end

  def unbind
    puts "Tivo: Disconnected"
    reconnect '192.168.2.5', 31339
  end
end

class SharpAquos < EventMachine::Connection
  def post_init
    @volume = nil
    @timer = EM::PeriodicTimer.new(1) do
      puts "asking for volume"
      send_data "VOLM?   \r" if @volume.nil?
    end
  end

  def receive_data(data)
    puts "SharpAquos: #{data}"
    unless data.match(/ERR/) or data.match(/OK/)
      @volume = data.to_i 
      @timer.cancel
    end
  end
  
  def send_command(command, val)
    if command.length == 4
      val += " " while val.length < 4
      send_data "#{command}#{val}\r"
    end
  end

  def change_volume(delta)
    @volume += delta
    send_command("VOLM", @volume.to_s)
  end

  def unbind
    puts "TV: Disconnected"
    reconnect '192.168.2.6', 10002
  end
end

class Guide
  attr_reader :listings
  def initialize
    @listings = {}
    EM::PeriodicTimer.new(10*60) { update }
    update
  end

  def update
    nearest_half_hour = Time.at((Time.now.to_f / (60 * 30)).to_i * 60* 30).to_i
    http = EventMachine::HttpRequest.new("http://tvlistings.zap2it.com/tvgrid/_xhr/schedule?time=#{nearest_half_hour}&lineupid=USA-IL63451-X&offset=250&count=200&zip=60654&tz=US%2FCentral").get
    http.callback {
      begin
        data = JSON.parse(http.response)

        @listings = data["data"]["results"]["stations"].map do |channel|
          shows = (channel["events"] || []).map do |event|
            program = event["program"]
            title = program["title"] + ": " + program["episodeTitle"]
            start = DateTime.parse(event["startTime"]).to_time.to_f * 1000
            {:start => start.to_i, :title => title }
          end
          {:channel => channel["channelNo"], :shows => shows}
        end
      rescue => e
        puts "Failed to get Guide"
      end
    }
  end

  private
  def channel_number(row)
    return 0 unless row.css('.tvg-station-channel').text.match(/Ch (\d+)/)
    puts row.css('.tvg-station-channel').text.match(/Ch (\d+)/)[1].to_i
    row.css('.tvg-station-channel').text.match(/Ch (\d+)/)[1].to_i
  end
end

EventMachine.run do
  class TvRemoteWeb < Sinatra::Base
    set :bind, '0.0.0.0'
    set :public_folder, File.dirname(__FILE__) + '/public'
    set :tv, EventMachine.connect('192.168.2.6', 10002, SharpAquos)
    set :tivo, EventMachine.connect('192.168.2.5', 31339, Tivo)
    set :guide, Guide.new

    get '/' do
      content_type :html
      File.read(File.join('public', 'index.html'))
    end
    
    get '/guide' do
      settings.guide.listings.to_json
    end

    get '/tv/volume/up' do
      settings.tv.change_volume 1
    end
    get '/tv/volume/down' do
      settings.tv.change_volume -1
    end
    get '/tv/power/off' do 
      settings.tv.send_command("POWR", "0")
    end

    get '/tivo/ch/:chan' do |chan|
      settings.tv.send_command("POWR", "1")
      settings.tv.send_command("IAVD", "1")
      settings.tivo.send_data "FORCECH #{chan}\r"
      chan
    end

    get '/tivo/:command/:val' do |command, val|
      settings.tivo.send_data "#{command} #{val}\r"
      val
    end
  end

  TvRemoteWeb.run!
  Signal.trap("INT")  { EventMachine.stop }
  Signal.trap("TERM") { EventMachine.stop }
end
