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

require 'vrlib'
require 'gtksourceview2'

class Interface
  include GladeGUI

 def initialize(protocol)
	@protocol = protocol
    @protocol.events.watch(self,  :error_received, :connection_closed , :address_in_use, :start_listening )

	@csv_filter = Gtk::FileFilter.new
	@csv_filter.add_pattern('*.csv')
	@csv_filter.name = "CSV"

 end


 def show()
   Gtk::Settings.default.gtk_menu_bar_accel = "<shift>F10"
   load_glade(__FILE__)
    @builder["window1"].signal_connect('destroy') {
		Gtk.main_quit
		exit
	}
   read_keys

   @connection_context = @builder["statusbar1"].get_context_id("connection")
   @error_context = @builder["statusbar1"].get_context_id("error")

   @builder["statusbar1"].push( @connection_context , @connection_message) unless @connection_message == nil

   @protocol.events.watch(self,:run_stopped,:run_started, :connection_init)

   @sourceview = Gtk::SourceView.new
   @editor = PhpEditor.new( @sourceview , @protocol)
   @builder["scrolledwindow1"].add(@sourceview)

   @protocol.events.watch(@editor,:source_received, :stack_received )
   @protocol.events.watch(@editor, :breakpoint_set , :breakpoint_removed , :offline_breakpoint_set,  :offline_breakpoint_removed  )

   @trace = Trace.new(@protocol)
   @builder["stack"].add(@trace)
   @protocol.events[:stack_received] = @trace

   @breakpoints = Breakpoints.new(@protocol)
   @builder["breakpoints"].add(@breakpoints)
   @protocol.events.watch(@breakpoints, :breakpoint_set , :breakpoint_removed , :offline_breakpoint_set,  :offline_breakpoint_removed  )

   @inspector = Inspector.new(@protocol)
   @builder["inspector"].add(@inspector)
   @protocol.events[:context_received] = @inspector
   @protocol.events[:global_context_received] = @inspector

   @console = Console.new(@protocol,@builder["console_entry"], @builder['console_result'])
   @protocol.events[:eval_result_received] = @console

   @builder["highlight_text"].active = @protocol.preferences[:highlight_text].nil? || @protocol.preferences[:highlight_text]
   @builder["highlight_text"].signal_connect( "toggled" ) do |w|
	 @editor.highlight =	w.active?
   end

   @builder["show_linenumbers"].signal_connect( "toggled" ) do |w|
	 @editor.show_line_numbers = w.active?
   end

  @breakpoints.row_clicked do |file, line|
	 @editor.open_file(file,line)
  end

  @trace.row_clicked do |file, line,level|
		@editor.open_file(file,line)
		@protocol.get_context(level)
  end	

   show_window() 
 end


   def run
		@protocol.run
   end

   def step_over
		@protocol.step_over
   end

   def step_into
	 @protocol.step_into
   end
	
   def step_out
	 @protocol.step_out
   end

   def stop
	 @protocol.stop
   end

   def scrollto_run
	 @editor.scrollto_run
   end

 def clear_console
	@console.clear	
 end

 def clear_breakpoints
	@protocol.breakpoints.clear
 end

 def show_preferences
	Preferences.new(@protocol).show(self)
 end

 def connection_init
	self.excecution_controls_sensitive = true
	@builder["stop"].sensitive = true
	@builder["open_file"].sensitive = true
	show_connection_status("Connected")
 end

 def run_stopped
	self.excecution_controls_sensitive = true
 end

 def run_started
	self.excecution_controls_sensitive = false
 end

 #conneciton events

 def error_received(message)
	@builder["statusbar1"].push( @error_context ,"ERROR: " + message )
	Thread.new{
	  sleep 5
	  @builder["statusbar1"].pop( @error_context)
	}
 end

 def connection_closed
	@editor.remove_run_cursor
	self.excecution_controls_sensitive = false
	@builder["stop"].sensitive = false
	@builder["open_file"].sensitive = false
	show_connection_status("Conection closed")
 end

 def start_listening 
	show_connection_status("Listening")
 end

 def address_in_use
	show_connection_status("Address already in use")
 end



 def excecution_controls_sensitive=(value)
	@excecution_controls_sensitive= value
	["run_button","step_over","step_into", "step_out" , "debugger", "scrollto_run"].each do |widget_name|
		@builder[widget_name].sensitive = value
	end
 end

 def show_connection_status(message)
	if @builder.nil? || @builder["statusbar1"].nil?  then
		@connection_message = message
	else
		@builder["statusbar1"].pop( @connection_context ).push( @connection_context , message)
	end
 end


 def editor_copy_clipboard
	@sourceview.copy_clipboard
 end

 #dialogs ----

 def open_file
		dialog = Gtk::FileChooserDialog.new("Open File",
                                     @builder["window1"],
                                     Gtk::FileChooser::ACTION_OPEN,
                                     nil,
                                     [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL],
                                     [Gtk::Stock::OPEN, Gtk::Dialog::RESPONSE_ACCEPT])

		dialog.current_folder = File.dirname(@editor.filename.gsub("file://","")) unless @editor.filename.nil?

		if dialog.run == Gtk::Dialog::RESPONSE_ACCEPT
		  @editor.open_file("file://#{dialog.filename}")
		end
		dialog.destroy
 end

 def save_breakpoints
		dialog = Gtk::FileChooserDialog.new("Save Breakpoints",
                                     @builder["window1"],
                                     Gtk::FileChooser::ACTION_SAVE,
                                     nil,
                                     [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL],
                                     [Gtk::Stock::SAVE, Gtk::Dialog::RESPONSE_ACCEPT])

		#dialog.current_folder = File.dirname(@editor.filename.gsub("file://",""))

		dialog.add_filter(@csv_filter)
		if dialog.run == Gtk::Dialog::RESPONSE_ACCEPT
			@protocol.breakpoints.save_csv(dialog.filename)
		end
		dialog.destroy
 end


 def load_breakpoints
		dialog = Gtk::FileChooserDialog.new("Load Breakpoints",
                                     @builder["window1"],
                                     Gtk::FileChooser::ACTION_OPEN,
                                     nil,
                                     [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL],
                                     [Gtk::Stock::OPEN, Gtk::Dialog::RESPONSE_ACCEPT])

		#dialog.current_folder = File.dirname(@editor.filename.gsub("file://",""))
		dialog.add_filter(@csv_filter)

		if dialog.run == Gtk::Dialog::RESPONSE_ACCEPT
			@protocol.breakpoints.load_csv(dialog.filename)
		end
		dialog.destroy
 end


 def goto_line
   entry = Gtk::Entry.new()
   dialog = Gtk::Dialog.new("Go to line",
                             @builder["window1"],
                             Gtk::Dialog::DESTROY_WITH_PARENT,
                             [ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_NONE ])

    # Ensure that the dialog box is destroyed when the user responds.
    dialog.signal_connect('response') { @editor.scrollto_line(entry.text.to_i) ;  dialog.destroy }

    dialog.vbox.add(entry)
    dialog.show_all
 end


 def read_keys
   @builder["window1"].signal_connect('key-press-event'){ |w,e|
	next unless @excecution_controls_sensitive

	case e.keyval 
	when Gdk::Keyval::GDK_F9 then
		@protocol.run
	when Gdk::Keyval::GDK_F10 then	
		@protocol.step_over
	when Gdk::Keyval::GDK_F11 then	
		if e.state.shift_mask? then
			@protocol.step_out
		else
			@protocol.step_into
		end
	end
   }
 end

 def about 
   dialog = Gtk::Dialog.new("About XDEBUG client - ruby/gtk",
                             @builder["window1"],
                             Gtk::Dialog::DESTROY_WITH_PARENT,
                             [ Gtk::Stock::CLOSE, Gtk::Dialog::RESPONSE_NONE ])

 
    dialog.signal_connect('response') { dialog.destroy }
	dialog.vbox.add(Gtk::Label.new("Visual client for XDEBUG written in ruby+gtk"))
    dialog.vbox.add(Gtk::Label.new("©2014 Fabian Fiorotto"))
    dialog.show_all
 end

end
