/*  Ease, a GTK presentation application
    Copyright (C) 2010 Nate Stedman

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

/**
 * A simple implementation of a widget using {@link Source.List}.
 *
 * Source.View consists of a {@link Source.List}, a separator, and a Gtk.Bin
 * packed into a Gtk.HBox.
 */
public class Source.View : BaseView
{	
	/**
	 * Creates an empty Source.View. Add groups with add_group().
	 */
	public View()
	{
		// create the bin and list widgets
		base();
		
		// create the hbox widget and build the full view
		var hbox = new Gtk.HBox(false, 0);
		hbox.pack_start(list, false, false, 0);
		hbox.pack_start(new Gtk.VSeparator(), false, false, 0);
		hbox.pack_start(bin, true, true, 0);
		add(hbox);
	}
}

