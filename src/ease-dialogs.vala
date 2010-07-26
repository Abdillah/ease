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
 * Creates "open file" windows.
 */
public class Ease.OpenDialog : GLib.Object
{
	/**
	 * Displays an "Open" dialog.
	 * 
	 * Used for loading previously saved files. This is a static method.
	 */
	public static void run()
	{
		var dialog = new Gtk.FileChooserDialog(_("Open File"),
		                                       null,
		                                       Gtk.FileChooserAction.OPEN,
		                                       "gtk-cancel",
		                                       Gtk.ResponseType.CANCEL,
		                                       "gtk-open",
		                                       Gtk.ResponseType.ACCEPT);
		
		// filter to only .ease files
		var filter = new Gtk.FileFilter();
		filter.add_pattern("*.ease");
		dialog.filter = filter;

		if (dialog.run() == Gtk.ResponseType.ACCEPT)
		{
			Main.open_file(dialog.get_filename() + "/");
		}
		dialog.destroy();
	}
}

/**
 * Creates and runs a "save" dialog with the given title. Returns null if
 * cancelled, otherwise returns the selected path
 *
 * @param title The dialog's title.
 * @param modal The window that the dialog should be modal for.
 */
public string? save_dialog(string title, Gtk.Window? modal)
{
	var dialog = new Gtk.FileChooserDialog(title,
	                                       modal,
	                                       Gtk.FileChooserAction.SAVE,
	                                       "gtk-save",
	                                       Gtk.ResponseType.ACCEPT,
	                                       "gtk-cancel",
	                                       Gtk.ResponseType.CANCEL,
	                                       null);
		
	if (dialog.run() == Gtk.ResponseType.ACCEPT)
	{
		// clean up the file dialog
		string path = dialog.get_filename();
		dialog.destroy();
		return path;
	}
	else
	{
		dialog.destroy();
		return null;
	}
}
