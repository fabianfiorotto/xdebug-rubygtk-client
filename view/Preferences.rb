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

class Preferences
  include GladeGUI

  attr_reader :highlight_text


  def initialize(protocol)
	@protocol = protocol
  end

  def before_show
	@builder["port_number"].value = @protocol.port_number
	@builder["highlight_text"].active = @protocol.preferences[:highlight_text].nil? || @protocol.preferences[:highlight_text]
  end

  def save_preferences
	@protocol.port_number= @builder["port_number"].value
	@protocol.preferences[:highlight_text] = @builder["highlight_text"].active?
	@protocol.save_preferences
	destroy_window
  end

end
