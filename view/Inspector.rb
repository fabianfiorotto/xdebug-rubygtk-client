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

class Inspector < VR::TreeView
 
 def initialize(protocol)
	@protocol = protocol
	super({:name => String, :type => String, :value => String})
 end

 def context_received(context)
	self.model.clear
	context.each{ |context_property|
		show_property(nil,context_property) 
	}
	@protocol.get_global_cotext #configurable?
 end

 def global_context_received(context)
	global = add_row(nil, :name => "GLOBALS")
	context.each{ |context_property|
		show_property(global,context_property) 
	}
 end


 def show_property(row,context_property)
	new_row = add_row(row, :name => context_property[:name], :type => context_property[:type], :value => show_value(context_property))
	if context_property[:numchildren] > 0 then
		context_property[:children].each do |child|
			show_property(new_row,child)
		end
	end
 end

 def show_value(context_property)
	case(context_property[:type])
	when 'uninitialized' then
	 return ""
	when 'int'
	 return context_property[:value]
	when 'bool'
	 return context_property[:value] == 1 ? "true" : "false"
	when 'array'
	 return "[#{context_property[:numchildren]}]"
	when 'string'
	 return context_property[:value].inspect
	when 'object'
	 return "(#{context_property[:classname]})"
	else
		return '?'
	end
 end

end

#/home/fabian/.rvm/gems/ruby-2.0.0-p0/gems/visualruby-1.0.16/visualruby_examples/treeview
