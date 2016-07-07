#!/usr/bin/env ruby
# Copyright (c) 2015-2016, Nascent Objects Inc
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions 
# are met:
#
# 1. Redistributions of source code must retain the above copyright 
#    notice, this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright 
#    notice, this list of conditions and the following disclaimer in 
#    the documentation and/or other materials provided with the 
#    distribution.
#
# 3. Neither the name of the copyright holder nor the names of its 
#    contributors may be used to endorse or promote products derived 
#    from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS 
# FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE 
# COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, 
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT 
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN 
# ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
# POSSIBILITY OF SUCH DAMAGE.


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
respond_on(SHELL_PROMPT, "timedatectl set-timezone America/Los_Angeles\n")
respond_on(SHELL_PROMPT, "systemctl enable wpa_supplicant\n")
respond_on(SHELL_PROMPT, "systemctl start wpa_supplicant\n")
respond_on(SHELL_PROMPT, "systemctl restart mdns\n")
respond_on(SHELL_PROMPT, "sync\n")
respond_on(SHELL_PROMPT, "exit\n")

$serialport.close

puts "Edison setup complete."
puts "Hostname: #{new_hostname}.local"
