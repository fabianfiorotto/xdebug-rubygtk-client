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

require './protocol/xdebug_connect.rb'
require './protocol/xdebug_protocol.rb'
require './protocol/event_manager.rb'
require './protocol/breakpoint.rb'
require './protocol/breakpoint_manager.rb'

require './view/Interface.rb'
require './view/Editor.rb'
require './view/Trace.rb'
require './view/Inspector.rb'
require './view/Breakpoints.rb'
require './view/Console.rb'
require './view/PhpEditor.rb'
require './view/Preferences.rb'


xdebug = XDebugProtocol.new

interface = Interface.new(xdebug)

 Thread.start() do 
	begin
	 interface.show
	 rescue Exception => e
		exit if e.class == SystemExit
		print e.message
		print e.backtrace
	 end
 end 


 xdebug.main


