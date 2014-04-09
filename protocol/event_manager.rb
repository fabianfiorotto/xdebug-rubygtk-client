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


class EventManager

 def initialize
	@events = {}
 end

 def dispatch(name,*args)
	if @events.has_key?(name) && !@events[name].empty? then
		@events[name].each{|handler| handler.send(name,*args) if handler.respond_to?(name) }
    end
 end

 def []=(name,handler) 
	@events[name] = [] unless  @events.has_key?(name)
	@events[name] << handler
 end
 
 def watch(handler,*names)
 	names.each{|name| self[name] = handler }
 end

end
