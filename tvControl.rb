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
    reconnect '192.168.1.7', 31339
  end
end

class SharpAquos < EventMachine::Connection
  def post_init
    @volume = nil
    @timer = EM::PeriodicTimer.new(1) do
      puts "asking for volume"
      send_data "VOLM?   \r" if @volume.nil?
    end
    EM::Timer.new(5) do
      @volume = 15 if @volume.nil?
      @timer.cancel
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

  def set_volume(volume)
    @volume = volume
    change_volume(0)
  end

  def unbind
    puts "TV: Disconnected"
    reconnect '192.168.1.3', 10002
  end
end

class Guide
  attr_reader :listings
  URL = "https://tvschedule.zap2it.com/api/grid?lineupId=USA-IL63451-DEFAULT&timespan=3&headendId=IL63451&country=USA&device=X&postalCode=60654&isOverride=true&pref=h&userId=-&aid=gapzap&time="

  def initialize
    @listings = {}
    EM::PeriodicTimer.new(10*60) { update }
    update
  end

  def update
    http = EventMachine::HttpRequest.new(URL + (Time.now.to_i.to_s)).get
    http.callback {
      data = JSON.parse(http.response)

      channels = data["channels"].select do |channel|
        num = channel["channelNo"].to_i
        num > 600 && num < 700
      end

      @listings = channels.map do |channel|
        shows = channel["events"].map do |event|
          start_ms = DateTime.parse(event["startTime"]).strftime("%Q")
          title = event["program"]["title"]
          title = "Womens NCAAB" if title.match(/Women's College Basketball/)
          title = "NCAAB" if title.match(/College Basketball/)
          subtitle = event["program"]["episodeTitle"] || ""
          full_text = title + " " + subtitle
          {:start => start_ms, :title => full_text}
        end
        {:channel => channel["channelNo"].to_i, :shows => shows}
      end
    }
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
    get '/tv/volume/:vol' do |vol|
      settings.tv.set_volume vol.to_i
    end
    get '/tv/mute' do
      settings.tv.send_command("MUTE","1")
    end
    get '/tv/unmute' do
      settings.tv.send_command("MUTE","2")
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

    get '/fastForward/:min' do |min|
      mins = 2 * min.to_i
      mins.times do
        settings.tivo.send_data "IRCODE ADVANCE\r"
      end
      min
    end
    
    get '/shutdown' do
      system "shutdown -h now"
    end
  end

  TvRemoteWeb.run!
  Signal.trap("INT")  { EventMachine.stop }
  Signal.trap("TERM") { EventMachine.stop }
end
