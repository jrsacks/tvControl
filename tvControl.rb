#!/usr/bin/env ruby
# encoding: utf-8

require 'eventmachine'
require 'sinatra'
require 'socket'

class Tivo < EventMachine::Connection
  def receive_data(data)
    puts "Tivo: #{data}"
  end

  def unbind
    puts "Tivo: Disconnected"
    reconnect '192.168.2.5', 31339
  end
end

class Tv < EventMachine::Connection
  def post_init
    @volume = nil
    @timer = EM::PeriodicTimer.new(1) do
      puts "asking for volume"
      send_data "VOLM?   \r" if @volume.nil?
    end
  end

  def receive_data(data)
    puts "Tv: #{data}"
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
    reconnect '192.168.2.7', 10002
  end
end


EventMachine.run do
  class App < Sinatra::Base
    set :bind, '0.0.0.0'
    set :public_folder, File.dirname(__FILE__) + '/public'
    set :tv, EventMachine.connect('192.168.2.7', 10002, Tv)
    set :tivo, EventMachine.connect('192.168.2.5', 31339, Tivo)

    get '/' do
      content_type :html
      File.read(File.join('public', 'index.html'))
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

  App.run!
  Signal.trap("INT")  { EventMachine.stop }
  Signal.trap("TERM") { EventMachine.stop }
end
