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


class XDebugProtocol < XDebugConnection

 attr_reader :events
 attr_reader :breakpoints

 def initialize
	@events = EventManager.new
	@breakpoints = BreakpointManager.new(self)
	super	
	@events.watch(@breakpoints,:connection_init,:connection_closed )
 end


 def init_packet_received(message)
	@events.dispatch(:connection_init)
	filename = message.root.attribute('fileuri').to_s
	send_command(  'source', { 'f' => filename }){ |message, command,  params,  data|
		source_received(message, command,  params,  data)
	} 
 end

 def run
	@events.dispatch(:run_started);
	send_command( 'run' ){ |message, command,  params,  data|
		run_stopped(message, command,  params,  data)
	}
 end

 def step_over
	@events.dispatch(:run_started);
	send_command( 'step_over'){ |message, command,  params,  data|
		run_stopped(message, command,  params,  data)
	}
 end

 def step_into
	@events.dispatch(:run_started);
	send_command( 'step_into'){ |message, command,  params,  data|
		run_stopped(message, command,  params,  data)
	}
 end

 def stop
	@events.dispatch(:run_started);
	send_command( 'stop'){ |message, command,  params,  data|
		run_stopped(message, command,  params,  data)
	}
 end

 def step_out
	@events.dispatch(:run_into);
	send_command( 'step_out'){ |message, command,  params,  data|
		run_stopped(message, command,  params,  data)
	}
 end

 def get_source(filename)
	if @client then
		send_command(  'source', { 'f' => filename }){ |message, command,  params,  data|
			source_received(message, command,  params,  data)
		}   
	else
		#offline method only valid in localhost
		@events.dispatch(:source_received, filename , File.read(filename.gsub("file://",'')))
	end
 end 

 def source_received(message, command,  params,  data)
	@events.dispatch(:source_received, params["f"] , Base64.decode64(message.root.text.to_s))
 end

 def run_stopped(message, command, params, data)
	p message.root.attribute('status')
	case message.root.attribute('status').to_s 
	when "break" then
		@events.dispatch(:run_stopped)
		send_command('stack_get'){ |message, command,  params,  data|
		  stack_received(message, command,  params,  data)
		}
		self.get_context
	when "stopping" then
		self.stop
	when "stopped" then
		@events.dispatch(:run_stopped)
		print "STOPPED\n"
	end
 end

 def stack_received(message, command, params, data)
	stack = []
	message.root.each_element do |element|
	 stack << {
		 level: element.attribute('level').to_s.to_i,
		 type:  element.attribute('type').to_s,
		 filename:  element.attribute('filename').to_s,
		 lineno: element.attribute('lineno').to_s.to_i - 1,
		 where:  element.attribute('where').to_s,
		 cmdbegin:  element.attribute('cmdbegin').to_s,
		 cmdend:  element.attribute('cmdend').to_s
	 }
	end
	@events.dispatch(:stack_received, stack );
 end


 def get_context(deep = nil)
	params = (deep == nil) ? nil : { 'd' => deep }  

	send_command("context_get",params){ |message, command,  params,  data|
	    context = []
		context_count = message.root.count
		message.root.each_element do |element|
			context << process_context_property(element)
		end
		
		@events.dispatch(:context_received , context)
	}	
 end

 def get_global_cotext
	send_command("context_get",{'c' => 1}){ |message, command,  params,  data|
	    context = []
		context_count = message.root.count
		message.root.each_element do |element|
			if element.attribute('name').to_s != "GLOBALS" then
				context << process_context_property(element)
			end
		end
		
		@events.dispatch(:global_context_received , context)
	}	
 end



 def process_context_property(element)
	property = {
				name: element.attribute('name').to_s,
				type: element.attribute('type').to_s,
				numchildren: element.attribute('numchildren').to_s.to_i,
				value: element.text.to_s
			}
	if property[:numchildren] > 0 then
		property[:children] = []
		element.each_element do |e|
			property[:children] << process_context_property(e)
		end
	end
	if property[:type] == "object" then
		property[:classname] =  property[:children].shift[:value]
	end
	if property[:type] == "string" && property[:name] != "CLASSNAME" then
		property[:value] = Base64.decode64(property[:value])
	end
	return property
 end


 def context_eval(string)
	send_command("eval",nil,string){ |message, command,  params,  data|
		result = []
		message.root.each_element do |element|
			result << process_context_property(element)
		end
		@events.dispatch(:eval_result_received , string , result)
	} 
 end

 def errormessage_received(error_message)
	@events.dispatch(:error_received , error_message)
	super
 end

 def disconnected
	@events.dispatch(:connection_closed )
	super
 end

 def listening
	@events.dispatch(:start_listening )
 end


 def address_in_use
	@events.dispatch(:address_in_use )
	super
 end


end

#protcol http://xdebug.org/docs-dbgp.php
