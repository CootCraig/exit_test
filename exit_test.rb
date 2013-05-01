require 'rubygems'
require 'bundler/setup'
require 'celluloid/autostart'
require 'date'

class MyExitActor
  include Celluloid
  def initialize
    after(10) { call_exit }
  end
  def call_exit
    exit(1)
  end
end
class MyChainedActor
  include Celluloid
  def initialize(key,speak_to_key)
    @key = key
    @speak_to_key = speak_to_key || nil
  end
  def speak(msg)
    puts "#{@key} heard #{msg}"
    Celluloid::Actor[@speak_to_key].speak("#{@key}->#{msg}") if @speak_to_key
  end
end
class ExitTestApp
  include Celluloid
    def initialize
      @last_actor = nil
      @app_supervision_group = Celluloid::SupervisionGroup.run!
      (1..4).each do |i|
        actor_sym = i.to_s.to_sym
        @last_actor = actor_sym
        @app_supervision_group.supervise_as(actor_sym,MyChainedActor,actor_sym,(i==1 ? nil : (i-1).to_s.to_sym))
      end
      @app_supervision_group.supervise_as(:exit_actor,MyExitActor)
      every(2) { announce_time }
    end
    def announce_time
      Celluloid::Actor[@last_actor].speak("Time is #{Time.now}")
    end
end
ExitTestApp.new
sleep

