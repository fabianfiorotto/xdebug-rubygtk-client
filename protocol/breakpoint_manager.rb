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
	 @breakpoints = Hash.new{ |hash, key| hash[key] = {} }
	 @offline_breakpoints = []
	end

    def set(file,line)
		return if at?(file,line)
		@offline_breakpoints << {line: line , file: file} 
		@protocol.events.dispatch(:offline_breakpoint_set,file , line)
		@protocol.send_command("breakpoint_set", {'t' => 'line', 'f' => file, 'n' => line + 1}) do |message,  command,  params,  data|
			 line = params['n'].to_i - 1
			 file = params['f']
			 breakpoint_id = message.root.attribute('id').to_s
			 @breakpoints[file][line] =  breakpoint_id
			 @offline_breakpoints.delete({line: line , file: file})
			 @protocol.events.dispatch(:offline_breakpoint_removed,file , line)
			 @protocol.events.dispatch(:breakpoint_set, file , line , breakpoint_id)
		end 
	end


	def unset(file,line)
		if @offline_breakpoints.include?({line: line , file: file}) then
			@offline_breakpoints.delete({line: line , file: file})
			@protocol.events.dispatch(:offline_breakpoint_removed,file , line)
		end
		@protocol.send_command("breakpoint_remove", {'f' => file, 'n' => line + 1 , 'd' => @breakpoints[file][line] }) do |message,  command,  params,  data|
			file = params['f']
			line = params['n'].to_i - 1
		 	breakpoint_id = @breakpoints[file].delete(line )
			@protocol.events.dispatch(:breakpoint_removed, file, line, breakpoint_id)
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
		 @breakpoints[filename].has_key?(line)  or @offline_breakpoints.include?({line: line , file: filename})
	end

	def connection_init
		offline_breakpoints = @offline_breakpoints.clone
		@offline_breakpoints.clear
		offline_breakpoints.each do |breakpoint|
			set(breakpoint[:file],breakpoint[:line])
		end
	end

	def connection_closed
		@breakpoints.each_pair{ |file, hash |
			hash.each_key{ |line|
				@protocol.events.dispatch(:breakpoint_removed, file, line, @breakpoints[file][line])
				@protocol.events.dispatch(:offline_breakpoint_set,file , line)
				@offline_breakpoints << {line: line , file: file}
			} 
		}
		@breakpoints.clear
	end

	def clear
		breakpoints = @breakpoints.clone
		breakpoints.each_pair{ |file, hash |
			hash.each_key{ |line|
				unset(file,line)
			} 
		}
		@offline_breakpoints.clear
	end

	require 'csv'

   def to_csv
	CSV.generate do |csv|
		@breakpoints.each_pair{ |file, hash |
			hash.each_key{ |line|
				csv << [file,line]	
			} 
		}
		@offline_breakpoints.each{ |breakpoint|
				csv << [breakpoint[:file],breakpoint[:line]]	
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
		self.set(csv[0],csv[1].to_i)
	}
   end

end
