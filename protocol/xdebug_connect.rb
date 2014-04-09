# Copyright (C) 2014  Fabian Fiorotto

 # This program is free software: you can redistribute it and/or modify
 # it under the terms of the GNU General Public License as published by
 # the Free Software Foundation, either version 3 of the License, or
 # (at your option) any later version.
 #
 # This program is distributed in the hope that it will be useful,
 # ut WITHOUT ANY WARRANTY; without even the implied warranty of
 # MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 # GNU General Public License for more details.
 #
 # You should have received a copy of the GNU General Public License
 # along with this program.  If not, see <http://www.gnu.org/licenses/>.


require 'socket'
require 'rexml/document'
require 'base64'
require 'yaml'

class XDebugConnection

 attr_reader :port_number
 attr_reader :preferences

 def initialize
	yamlfile = File.dirname(__FILE__)+"/../.preferences.yml"
	@preferences = YAML::load_file(yamlfile)
	@port_number = @preferences[:port_number]
	@sent = {}
	@queue = []
	@thread = nil
 end


 def dispatch_message(message)
	case message.root.name
	 when "init" then init_packet_received(message)
	 when "response" then response_packet_received(message)

	 else
		print "Unknow tag #{message.root.name} \n"
    end
 end

 def main_thread
	  return if @socket.nil?
	  @thread = Thread.start do
	    begin
			loop{
				#sleep 2
				if @client == nil then
	 				listening
					@client = @socket.accept
					connection_openned
				end
				message = ""
				data , info=  @client.recvfrom(2048)
				data = data.split("\0")
				if data.empty? then
					#reiniciar el resto de las variables
					@queue.clear
					@client.close 
					@client = nil
					disconnected()
					next
				end
				bytes_recived = data[1].length 
				bytes_total = data[0].to_i
				message = data[1]
				while bytes_recived < bytes_total do
					 data , info=  @client.recvfrom(2048)
					 bytes_recived += data.length 
					 data.slice!("\0") if (bytes_recived == bytes_total + 1)
					 message += data
				end
				doc = REXML::Document.new(message)
				dispatch_message(doc)
			 }
		 rescue Exception => e
			print e.message
			print e.backtrace
		 end

		end
 end


 def main
	  	@client = nil

		begin
		 @socket = TCPServer.new('127.0.0.1',@port_number)
		rescue Errno::EADDRINUSE => e
			address_in_use
		end

		main_thread

		loop{
			sleep 0.1 #if @queue.empty? #no me sirve la var sent si saco esto
			if !@queue.empty? && @client != nil then
				message = @queue.shift
				@client.write format_command(* message[:args])
				print "sending message: \n"
				p message[:args]
				@sent["1"] = message
			end
		}
 end

 def format_command( command, args = nil, data = nil )
	#TODO: cambiar la firma de este metodo para pasar menoenos parametros cuando args = nil
	args = {} if args.nil?
	args["i"] = 1 
	strargs = "-" + args.map{|k,v| "#{k} #{v}"}.join(' -')
	strdata = data ? " -- " +  Base64.encode64(data) : ''
	return command + " " + strargs + strdata+ "\0"
 end

 def response_packet_received(message)
	if(message.root.elements.count == 1 &&  message.root.elements[1].name == "error")
		errormessage_received(message.root.elements[1].elements[1].text.to_s)
		return
	end

	transaction_id = message.root.attribute('transaction_id').to_s
	if(transaction_id) then
		message_sent = @sent[transaction_id]
		message_sent[:block].call( message , *message_sent[:args])
	end
 end

 def send_command(*args,&block)
	@queue << { args: args, block: block } unless @client.nil?
 end

 def init_packet_received(message)
	#override
 end


 def listening
 end

 def address_in_use
	print "ADDRESS ALREADY IN USE\n\n\n"
 end

 def connection_openned
	print "CONNECTION OPPENED\n\n\n"
 end

 def errormessage_received(error_message)
	print "ERROR: #{error_message} \n"
 end

 def disconnected
	print "DISCONNECTED\n"
 end


 def port_number=(port_number)
	return if @port_number == port_number
	@socket.close unless @socket.nil? || @socket.closed?
	@thread.kill unless @thread.nil?
	@port_number = port_number.to_i
	@preferences[:port_number] = @port_number
	begin
	 @socket = TCPServer.new('127.0.0.1',@port_number)
	 main_thread
	rescue Errno::EADDRINUSE => e
		address_in_use
	end
 end



 def save_preferences
	File.open(File.dirname(__FILE__)+"/../.preferences.yml", 'w+') {|f| f.write @preferences.to_yaml} 
 end

end
