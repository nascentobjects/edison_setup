#!/usr/bin/env ruby
require 'rubyserial'

$serialport = Serial.new '/dev/ttyUSB0', 115200
SHELL_PROMPT = ":~#"

def read(len)
  sleep 1
  return $serialport.read(len)
end

def respond_on(match, response)
   data = read(1000);
   if data =~ Regexp.new(match)
     $serialport.write(response)
   else
     puts "Couldn't find #{match}, got #{data} instead"
     throw :badMatch
   end
end

state = 0
hostname = ARGV[0]

$serialport.write("\n");

respond_on("login:", "root\n")
respond_on("word:", "prototype\n")
respond_on(SHELL_PROMPT, "echo #{hostname} > /etc/hostname\n") 
respond_on(SHELL_PROMPT, "hostname -F /etc/hostname\n")
respond_on(SHELL_PROMPT, "echo -e \"network={\\n  ssid=\\\"squishnet\\\"\\n  psk=\\\"s1lv3repoxy\\\"\\n}\" >> /etc/wpa_supplicant/wpa_supplicant.conf\n")
respond_on(SHELL_PROMPT, "exit\n")

$serialport.close
