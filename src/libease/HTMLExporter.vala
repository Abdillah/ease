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

namespace Ease
{
	/**
	 * Exports Ease {@link Document}s as HTML5 files
	 *
	 * HTMLExporter creates a save dialog and a progress dialog. The actual
	 * exporting is done with the {@link Document}, {@link Slide}, and
	 * {@link Element} classes. The exported {@link Document} reports back to
	 * HTMLExported when the export is complete, allowing the dialog to close.
	 *
	 * HTMLExporter also handles copying media files to the output directory.
	 */
	public class HTMLExporter : GLib.Object
	{
		private Gtk.Dialog window;
		private Gtk.ProgressBar progress;
		
		public string path { get; private set; }
		
		public HTMLExporter()
		{
			progress = new Gtk.ProgressBar();
		}
		
		public bool request_path(Gtk.Window win)
		{
			var dialog = new Gtk.FileChooserDialog("Export to HTML",
			                                       win,
			                                       Gtk.FileChooserAction.SAVE,
			                                       "gtk-save",
			                                       Gtk.ResponseType.ACCEPT,
			                                       "gtk-cancel",
			                                       Gtk.ResponseType.CANCEL,
			                                       null);
			
			if (dialog.run() == Gtk.ResponseType.ACCEPT)
			{
				// clean up the file dialog
				path = dialog.get_filename();
				dialog.destroy();
				
				// create the progress dialog
				window = new Gtk.Dialog();
				window.width_request = 400;
				window.set_title("Exporting as HTML");
				Gtk.VBox vbox = (Gtk.VBox)(window.get_content_area());
				vbox.pack_start(progress, true, true, 5);
				window.show_all();
				
				return true;
			}
			else
			{
				dialog.destroy();
				return false;
			}
		}
		
		public void add_progress(double amount)
		{
			progress.set_fraction(progress.get_fraction() + amount);
		}
		
		public void finish()
		{
			window.hide_all();
			window.destroy();
		}
		
		public void copy_file(string end_path, string base_path)
		{
			var source = File.new_for_path(base_path + "/" + end_path);
			var destination = File.new_for_path(path + " " + end_path);

			try
			{
				// if the destination directory doesn't exist, make it
				var parent = destination.get_parent();
				if (!parent.query_exists(null))
				{
					parent.make_directory_with_parents(null);
				}
				
				// copy the image
				source.copy(destination,
					        FileCopyFlags.OVERWRITE,
					        null,
					        null);
			}
			catch (GLib.Error e)
			{
				var dialog = new Gtk.MessageDialog(null,
					                               Gtk.DialogFlags.NO_SEPARATOR,
					                               Gtk.MessageType.ERROR,
					                               Gtk.ButtonsType.CLOSE,
					                               "Error copying: %s",
					                               e. message);
				dialog.title = "Error Copying File";
				dialog.border_width = 5;
				dialog.run();
				dialog.destroy();
			}
		}
	}
}
