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

class Console

 def initialize(protocol,entry , result)
	@protocol = protocol
	@result = result
	@result.homogeneous = false

	entry.signal_connect( "activate" ) do |w|
		@protocol.context_eval(w.text)
		w.text = ""
	end

 end

 def clear
	@result.each{ |widget|
		@result.remove(widget)
	}
 end

 def eval_result_received(command, result)
	expander = Gtk::Expander.new(command)
	inspector = Inspector.new(@protocol)
	result.each{ |val|
		inspector.show_property(nil,val)
	}
	expander.add(inspector)
	@result.pack_start(expander, false, false,  0)
	#@result.add(expander)
	expander.show
	inspector.show
 end

end
