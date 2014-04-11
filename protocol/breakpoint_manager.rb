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


class BreakpointManager

	def initialize(protocol)
	 @protocol = protocol
	 @breakpoints = []
	end


	def offline_breakpoints
		@breakpoints.select{ |breakpoint| breakpoint.offline }
	end

    def set(file,line)
		breakpoint = @breakpoints.detect{|b| b.file == file && b.line == line }
		if breakpoint == nil then
			breakpoint = Breakpoint.new(file,line)
			@breakpoints << breakpoint
		else
			return if  breakpoint.online?
		end
		@protocol.events.dispatch(:offline_breakpoint_set,breakpoint)
		@protocol.send_command("breakpoint_set", {'t' => 'line', 'f' => file, 's' => breakpoint.status ,'n' => line + 1}) do |message,  command,  params,  data|
			 breakpoint.breakpoint_id =  message.root.attribute('id').to_s
			 breakpoint.offline = false
			 @protocol.events.dispatch(:offline_breakpoint_removed,breakpoint)
			 @protocol.events.dispatch(:breakpoint_set, breakpoint)
		end 
	end


	def unset(file,line)
		breakpoint = @breakpoints.detect{|b| b.file == file && b.line == line }
		@protocol.send_command("breakpoint_remove", {'f' => file, 'n' => line + 1 , 'd' => breakpoint.breakpoint_id }) do |message,  command,  params,  data|
		 	@breakpoints.delete(breakpoint)
			@protocol.events.dispatch(:breakpoint_removed, breakpoint)
		end
	end


	def enable(file,line)
		breakpoint = @breakpoints.detect{|b| b.file == file && b.line == line }
		@protocol.send_command("breakpoint_update", { "s" => "enabled", 'd' => breakpoint.breakpoint_id }) do |message,  command,  params,  data|
			breakpoint.disabled = false
			@protocol.events.dispatch(:breakpoint_disabled, breakpoint)
		end
	end


	def disable(file,line)
		breakpoint = @breakpoints.detect{|b| b.file == file && b.line == line }
		@protocol.send_command("breakpoint_update", { "s" => "disabled"  , 'd' => breakpoint.breakpoint_id }) do |message,  command,  params,  data|
			breakpoint.disabled = true
			@protocol.events.dispatch(:breakpoint_enabled, breakpoint)
		end
	end


	def toggle(file,line)
		if(at?(file,line)) then
		  unset(file,line)
		else
		  set(file,line)
		end
	end


	def at?(filename,line)
		 @breakpoints.any?{|b| b.file == filename && b.line == line}
	end

	def connection_init
		@breakpoints.each do |breakpoint|
		  if breakpoint.offline && breakpoint.enabled? then
			set(breakpoint.file ,breakpoint.line)
		  end
		end
	end

	def connection_closed
		@breakpoints.each{ |breakpoint|
				@protocol.events.dispatch(:breakpoint_removed, breakpoint)
				@protocol.events.dispatch(:offline_breakpoint_set,breakpoint)
				breakpoint.offline = true
		}
	end

	def clear
		@breakpoints.each{ | breakpoint |
			unset(breakpoint.file,breakpoint.line)
		}
		@breakpoints.clear
	end

	require 'csv'

   def to_csv
	CSV.generate do |csv|
		@breakpoints.each{ |breakpoint|
				csv << [breakpoint.file,breakpoint.line, (breakpoint.offline ? 0 : 1) ]	 
		}
	end
   end
	
   def save_csv(filename)
	file = File.new(filename,"w+")
	file.write(self.to_csv)
	file.close
   end

   def load_csv(filename)
	CSV.foreach(filename){ |csv|
		self.set(csv[0],csv[1].to_i, csv[1].to_i == 0 )
	}
   end

end
