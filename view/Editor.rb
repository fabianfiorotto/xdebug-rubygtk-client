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

class Editor

 attr_reader :filename
 attr_reader :highlight

 def initialize( widget ,  protocol)
  @widget = widget
  @widget.editable = false
  @protocol = protocol
  @source = ""
  @buffer = @widget.buffer
  @breakpoint_tag = @buffer.create_tag("breakpoint_mark",{"paragraph-background"=>"red"} )
  @offline_breakpoint_tag = @buffer.create_tag("offline_breakpoint_mark",{"paragraph-background"=>"dark orange"} )
  @runstop_tag = @buffer.create_tag("runstop_mark",{"paragraph-background"=>"green"} )
  @stoprun_pos = nil

  @widget.show_line_numbers = true
  @widget.insert_spaces_instead_of_tabs = true
  @widget.indent_width = 4
  @widget.show_right_margin = true
  @widget.right_margin_position = 80



  @widget.signal_connect 'button_press_event' do |widget, event|
	if event.event_type == Gdk::Event::BUTTON2_PRESS and event.button == 1 then
	 start , ends , selected  = @buffer.selection_bounds
	 lineno = start.line
	 @protocol.breakpoints.toggle(@filename, lineno )
	end
  end
 end

 def show_line_numbers=(value)
	@widget.show_line_numbers = value
 end


 def highlight=(value)
	@widget.buffer.highlight_syntax = value
 end

 def open_file(filename, line = nil)
	if(@filename != filename) then
	 @protocol.get_source(filename)
	 @line = line
	else
		if line.nil? then
			scrollto_run
		else
			scrollto_line(line)
		end
	end
 end

 def source_received(filename,source)
	print "recivido: #{filename }\n\n\n"
	@source = source
	@filename = filename

	refresh_textbuffer

	Thread.new{
		sleep 1
		if @line.nil? then
			scrollto_run
		else
			scrollto_line(@line)
			@line = nil
		end
	}

 end

 def remove_run_cursor
	unless @runstop_pos.nil? then
		start = @buffer.get_iter_at_line(@runstop_pos + 1 )
		ends = @buffer.get_iter_at_line(@runstop_pos + 2 )
		@buffer.remove_tag(@runstop_tag, start, ends)
	end
	@runstop_pos = nil
 end


 def stack_received(stack)
	return if stack.empty? 

	remove_run_cursor

	lineno = stack.first[:lineno]
	filename = stack.first[:filename]
	@runstop_pos = lineno - 1

	if filename != @filename then
		@protocol.get_source(filename)
	end

	start = @buffer.get_iter_at_line(@runstop_pos +1)
	ends = @buffer.get_iter_at_line(@runstop_pos  + 2)
	@buffer.apply_tag(@runstop_tag, start, ends)
 end

 def breakpoint_set(file , lineno, breakpoint_id)
	if file == @filename then
		start = @buffer.get_iter_at_line(lineno)
		ends = @buffer.get_iter_at_line(lineno + 1)
		@buffer.apply_tag(@breakpoint_tag, start, ends)
	end
 end

 def breakpoint_removed(file , lineno, breakpoint_id)
	if file == @filename then
		start = @buffer.get_iter_at_line(lineno)
		ends = @buffer.get_iter_at_line(lineno + 1)
		@buffer.remove_tag(@breakpoint_tag, start, ends)
	end
 end 

 def offline_breakpoint_set(file , lineno)
	if file == @filename then
		start = @buffer.get_iter_at_line(lineno)
		ends = @buffer.get_iter_at_line(lineno + 1)
		@buffer.apply_tag(@offline_breakpoint_tag, start, ends)
	end
 end

 def offline_breakpoint_removed(file , lineno)
	if file == @filename then
		start = @buffer.get_iter_at_line(lineno)
		ends = @buffer.get_iter_at_line(lineno + 1)
		@buffer.remove_tag(@offline_breakpoint_tag, start, ends)
	end
 end


 def refresh_textbuffer
	@buffer.text = ""
	lines = @source.split("\n")
	lines.each_with_index do |line, index|
		start = @buffer.get_iter_at_offset(@buffer.end_iter.offset)
		if (@runstop_pos  == index - 1 ) then
		 @buffer.insert(start, line +"\n" , "runstop_mark")
		else
			if @protocol.breakpoints.at?(@filename,index) then
			 @buffer.insert(start, line +"\n" , "breakpoint_mark")
			else
		 	 @buffer.insert_at_cursor(line+"\n")
			end
		end
	end
 end


 def scrollto_run
	scrollto_line(@runstop_pos) unless @runstop_pos.nil?
 end

 def scrollto_line(line)
	adjustment =  @widget.parent.vadjustment
	return if adjustment.upper == adjustment.page_size 
	adjustment.value = adjustment.upper * (line.to_f / @buffer.line_count) 
 end

end
