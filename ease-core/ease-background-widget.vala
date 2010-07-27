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
 * A widget that controls the properties of an {@link Ease.Background}.
 */
public class Ease.BackgroundWidget : Gtk.Alignment
{
	private const string UI_FILE_PATH = "background.ui";
	private const string BG_DIALOG_TITLE = _("Select Background Image");
	
	private Gtk.ComboBox background_type;
	private Gtk.ListStore store;
	private Gtk.ComboBox gradient_type;
	private Gtk.VBox box_color;
	private Gtk.VBox box_gradient;
	private Gtk.VBox box_image;
	private Gtk.HScale grad_angle;
	
	private Gtk.ColorButton bg_color;
	private Gtk.ColorButton grad_color1;
	private Gtk.ColorButton grad_color2;
	private Gtk.FileChooserButton bg_image;
	
	private Background background;
	
	private bool silence_undo;
	private Document document;
	private Slide slide;
	private Element element;
	
	public BackgroundWidget(Background bg, Element e)
	{
		background = bg;
		document = e.parent.parent;
		element = e;
		init();
	}
	
	public BackgroundWidget.for_slide(Slide s)
	{
		document = s.parent;
		background = s.background;
		slide = s;
		init();
	}
	
	private void init()
	{	
		// load the GtkBuilder file
		var builder = new Gtk.Builder();
		try
		{
			builder.add_from_file(data_path(Path.build_filename(Temp.UI_DIR,
				                                                UI_FILE_PATH)));
		}
		catch (Error e) { error("Error loading UI: %s", e.message); }
		
		// add the root of the builder file to this widget
		add(builder.get_object("root") as Gtk.Widget);
		set(0, 1, 0, 0);
		
		// get controls
		box_color = builder.get_object("vbox-color") as Gtk.VBox;
		box_gradient = builder.get_object("vbox-gradient") as Gtk.VBox;
		box_image = builder.get_object("vbox-image") as Gtk.VBox;
		bg_color = builder.get_object("color-color") as Gtk.ColorButton;
		grad_color1 =
			builder.get_object("color-startgradient") as Gtk.ColorButton;
		grad_color2 =
			builder.get_object("color-endgradient") as Gtk.ColorButton;
		bg_image =
			builder.get_object("button-image") as Gtk.FileChooserButton;
		gradient_type =
			builder.get_object("combo-gradient") as Gtk.ComboBox;
		grad_angle = builder.get_object("hscale-angle") as Gtk.HScale;
		
		// display the correct UI
		display_bg_ui(background.background_type);
		
		// set up the gradient type combobox
		gradient_type.model = GradientType.list_store();
		
		// get the combobox
		background_type = builder.get_object("combobox-style") as Gtk.ComboBox;
		
		// build a liststore for the combobox
		store = new Gtk.ListStore(2, typeof(string), typeof(BackgroundType));
		Gtk.TreeIter iter;
		foreach (var b in BackgroundType.TYPES)
		{
			store.append(out iter);
			store.set(iter, 0, b.description(), 1, b);
		}
		
		var render = new Gtk.CellRendererText();
		
		background_type.pack_start(render, true);
		background_type.set_attributes(render, "text", 0);
		background_type.model = store;
		
		// set the background type combo box
		Gtk.TreeIter itr;
		BackgroundType type;
		store.get_iter_first(out itr);
		do
		{
			store.get(itr, 1, out type);
			if (type == background.background_type)
			{
				background_type.set_active_iter(itr);
				break;
			}
		} while (store.iter_next(ref itr));
		
		// set the gradient variant box
		GradientType grad_type;
		gradient_type.model.get_iter_first(out itr);
		do
		{
			gradient_type.model.get(itr, 1, out grad_type);
			if (grad_type == background.gradient.mode)
			{
				gradient_type.set_active_iter(itr);
				break;
			}
		} while (gradient_type.model.iter_next(ref itr));
		
		
		// connect signals
		builder.connect_signals(this);
	}
	
	private void emit_undo(UndoAction action)
	{
		if (!silence_undo)
		{
			if (slide != null) slide.undo(action);
			else element.undo(action);
		}
	}
	
	[CCode (instance_pos = -1)]
	public void on_background_changed(Gtk.Widget? sender)
	{
		Gtk.TreeIter itr;
		store.get_iter_first(out itr);
		
		// find the correct position
		for (int i = 0; i < background_type.active; i++)
		{
			store.iter_next(ref itr);
		}
		
		// get the background type at that position
		BackgroundType type;
		store.get(itr, 1, out type);
		
		// create an undo action
		var action = new UndoAction(background, "background-type");
		
		// ease doesn't provide a default for images, so one must be requested
		if (type == BackgroundType.IMAGE && background.image == null)
		{
			var dialog = new Gtk.FileChooserDialog(BG_DIALOG_TITLE,
			                                       widget_window(this),
			                                       Gtk.FileChooserAction.OPEN,
			                                       "gtk-cancel",
			                                       Gtk.ResponseType.CANCEL,
			                                       "gtk-open",
			                                       Gtk.ResponseType.ACCEPT);
			switch (dialog.run())
			{
				case Gtk.ResponseType.ACCEPT:
					try
					{
						var fname = dialog.get_filename();
						background.image_source = fname;
						var i = document.add_media_file(fname);
						background.image = i;
					}
					catch (GLib.Error e)
					{
						critical("Error adding background image: %s",
						         e.message);
					}
					dialog.destroy();
					break;
				case Gtk.ResponseType.CANCEL:
					action.apply();
					dialog.destroy();
					return;
			}
		}
		
		action.applied.connect((a) => {
			silence_undo = true;
			background_type.set_active(background.background_type);
			display_bg_ui(background.background_type);
			silence_undo = false;
		});
		
		// add properties to the UndoAction and report it to the controller
		switch (type)
		{
			case BackgroundType.COLOR:
				action.add(background, "color");
				break;
			case BackgroundType.GRADIENT:
				action.add(background, "gradient");
				break;
			case BackgroundType.IMAGE:
				action.add(background, "image");
				break;
		}
		
		background.background_type = type;
		
		emit_undo(action);
		
		// switch to that background type
		display_bg_ui(type);
	}
	
	[CCode (instance_pos = -1)]
	public void on_gradient_type_changed(Gtk.ComboBox? sender)
	{
		var action = new UndoAction(background.gradient, "mode");
		GradientType type;
		Gtk.TreeIter itr;
		sender.model.get_iter_first(out itr);
		for (int i = 0; i < sender.get_active(); i++)
		{
			sender.model.iter_next(ref itr);
		}
		sender.model.get(itr, 1, out type);
		background.gradient.mode = type;
		emit_undo(action);
	}
	
	[CCode (instance_pos = -1)]
	public void on_color_set(Gtk.ColorButton? sender)
	{
		UndoAction action = null;
		if (sender == bg_color)
		{
			action = background.color.undo_action();
			background.color.gdk = sender.color;
			action.applied.connect(() => {
				sender.set_color(background.gradient.end.gdk);
			});
		}
		else if (sender == grad_color1)
		{
			action = background.gradient.start.undo_action();
			background.gradient.start.gdk = sender.color;
			action.applied.connect(() => {
				sender.set_color(background.gradient.start.gdk);
			});
		}
		else if (sender == grad_color2)
		{
			action = background.gradient.end.undo_action();
			background.gradient.end.gdk = sender.color;
			action.applied.connect(() => {
				sender.set_color(background.gradient.end.gdk);
			});
		}
		if (action != null) emit_undo(action);
	}
	
	[CCode (instance_pos = -1)]
	public void on_file_set(Gtk.FileChooserButton? sender)
	{
		var action = new UndoAction(background, "image");
		action.add(background, "image-source");
		
		// slide might change in the meantime
				
		// set the button's filename when the action is applied
		action.applied.connect((a) => {
			// if slide changes, this is still ok
			if (background.image_source != null)
			{
				bg_image.set_filename(background.image_source);
			}
			else
			{
				bg_image.unselect_all();
			}
			
			display_bg_ui(background.background_type);
		});
		
		try
		{
			background.image_source = sender.get_filename();
			var i = document.add_media_file(sender.get_filename());
			background.image = i;
		}
		catch (GLib.Error e)
		{
			critical("Error adding background image: %s", e.message);
		}
		
		emit_undo(action);
	}
	
	[CCode (instance_pos = -1)]
	public void on_reverse_gradient(Gtk.Widget? sender)
	{
		// create an undo action
		var action = new UndoAction(background.gradient, "start");
		action.add(background.gradient, "end");
		
		// flip the gradient
		background.gradient.flip();
		
		// update the ui
		grad_color1.set_color(background.gradient.start.gdk);
		grad_color2.set_color(background.gradient.end.gdk);
		
		// reset the buttons when the action is applied
		action.applied.connect(() => {
			grad_color1.set_color(background.gradient.start.gdk);
			grad_color2.set_color(background.gradient.end.gdk);
		});
				
		// add the undo action
		emit_undo(action);
	}
	
	[CCode (instance_pos = -1)]
	public void on_set_angle(Gtk.Widget? sender)
	{
		var action = new UndoAction(background.gradient, "angle");
		background.gradient.angle =
			(sender as Gtk.HScale).adjustment.value;
		emit_undo(action);
		
		action.applied.connect((a) => {
			display_bg_ui(background.background_type);
		});
	}
	
	private void display_bg_ui(BackgroundType type)
	{
		switch (type)
		{
			case BackgroundType.COLOR:
				box_color.show_all();
				box_gradient.hide_all();
				box_image.hide_all();
				
				if (background.color == null)
				{
					background.color = Color.white;
				}
				background.background_type = BackgroundType.COLOR;
				
				bg_color.set_color(background.color.gdk);
								
				break;
			
			case BackgroundType.GRADIENT:
				box_color.hide_all();
				box_gradient.show_all();
				box_image.hide_all();
				
				if (background.gradient == null)
				{
					background.gradient = new Gradient(Color.black,
					                                         Color.white);
					gradient_type.set_active(background.gradient.mode);
				}
				background.background_type = BackgroundType.GRADIENT;
				
				grad_color1.set_color(background.gradient.start.gdk);
				grad_color2.set_color(background.gradient.end.gdk);
				
				grad_angle.adjustment.value = background.gradient.angle;
								
				break;
			
			case BackgroundType.IMAGE:
				box_color.hide_all();
				box_gradient.hide_all();
				box_image.show_all();
				
				background.background_type = BackgroundType.IMAGE;
				if (background.image_source != null)
				{
					bg_image.set_filename(background.image_source);
				}
				else
				{
					bg_image.unselect_all();
				}
							
				break;
		}
	}
}
