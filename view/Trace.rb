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

class Trace < VR::ListView

 def initialize(protocol)
	@protocol = protocol
	super({:file => String , :line => Numeric })
 end

 def row_clicked
	signal_connect 'button_press_event' do |widget, event|
		if event.event_type == Gdk::Event::BUTTON2_PRESS and event.button == 1 then
			row =  selected_rows[0]
			level = row.path.indices.first
			yield(row[:file],row[:line],level)
		end
	end
 end


 def stack_received(stack)
	self.model.clear
	stack.each{ |stack_trace|
		rowIter = add_row()
		rowIter[:file] = stack_trace[:filename]
		rowIter[:line] = stack_trace[:lineno]
	}
 end



end
