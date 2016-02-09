#!/usr/bin/env ruby
require 'rubyserial'

$serialport = Serial.new '/dev/ttyUSB0', 115200
SHELL_PROMPT = ":~#"

def read(len)
  sleep 1
  return $serialport.read(len)
end

def respond_on(match, command)
   data = read(1000);
   if data =~ Regexp.new(match)
     $serialport.write(command)
   else
     puts "Couldn't find #{match}, got #{data} instead"
     throw :badMatch
   end
end

def result(command)
   # clean out the buffer
   data = read(1000)
   $serialport.write(command)
   # read back the command
   $serialport.gets
   # get the actual result
   return $serialport.gets
end

state = 0

if ARGV.length > 0
 hostname = ARGV[0]
end

$serialport.write("\n");

respond_on("login:", "root\n")
respond_on("word:", "prototype\n")

if hostname
  respond_on(SHELL_PROMPT, "echo #{hostname} > /etc/hostname\n")
else
  respond_on(SHELL_PROMPT, "N=`cat /factory/serial_number | wc -c`\n")
  respond_on(SHELL_PROMPT, "cat /factory/serial_number | cut -c $(($N-8))-$(($N-3)) > /etc/hostname\n")
  new_hostname = result("cat /etc/hostname\n").chomp
end

respond_on(SHELL_PROMPT, "hostname -F /etc/hostname\n")
respond_on(SHELL_PROMPT, "echo -e \"network={\\n  ssid=\\\"squishnet\\\"\\n  psk=\\\"s1lv3repoxy\\\"\\n}\" >> /etc/wpa_supplicant/wpa_supplicant.conf\n")
respond_on(SHELL_PROMPT, "systemctl enable wpa_supplicant\n")
respond_on(SHELL_PROMPT, "systemctl start wpa_supplicant\n")
respond_on(SHELL_PROMPT, "systemctl restart mdns\n")
respond_on(SHELL_PROMPT, "exit\n")

$serialport.close

puts "Edison setup complete."
puts "Hostname: #{new_hostname}.local"
