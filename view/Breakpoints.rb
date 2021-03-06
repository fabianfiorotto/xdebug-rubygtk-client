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

class Breakpoints < VR::ListView


 def initialize(protocol)
	@protocol = protocol
	super({:file => String , :line => Numeric })
 end

 def row_clicked
	signal_connect 'button_press_event' do |widget, event|
		if event.event_type == Gdk::Event::BUTTON2_PRESS and event.button == 1 then
			row =  selected_rows[0]
			yield(row[:file],row[:line])
		end
	end
 end


 def breakpoint_set(file,line,breakpoint_id)
		each_row { |r|
		 return if r[:file] == file && r[:line] == line 
		}
		rowIter = add_row(:file => file, :line => line)
 end

 def breakpoint_removed(file,line,breakpoint_id)
		row = nil
		each_row { |r|
		 row = r if r[:file] == file && r[:line] == line 
		}
		model.remove(row) unless row.nil?
 end


 def offline_breakpoint_set(file,line)
		each_row { |r|
		 return if r[:file] == file && r[:line] == line 
		}
		rowIter = add_row(:file => file, :line => line)
 end

 def offline_breakpoint_removed(file,line)
		row = nil
		each_row { |r|
		 row = r if r[:file] == file && r[:line] == line 
		}
		model.remove(row) unless row.nil?
 end


end
