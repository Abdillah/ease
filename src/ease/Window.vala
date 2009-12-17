using Gtk;
using GtkClutter;

namespace Ease
{
	public class Window : Gtk.Window
	{
		public GtkClutter.Embed embed { get; set; }
		
		public Window()
		{
			this.title = "";
			
			this.set_default_size(800, 600);
			
			var vbox = new Gtk.VBox(false, 0);
			vbox.pack_start(create_menu_bar(), false, false, 0);
			vbox.pack_start(create_toolbar(), false, false, 0);
			
			embed = new GtkClutter.Embed();
			var color = Clutter.Color();
			color.from_string("Red");
			((Clutter.Stage)(embed.get_stage())).set_color(color);
			
			vbox.pack_start(embed, true, true, 0);
			
			this.add(vbox);
		}
		
		// signal handlers
		private void show_open_dialog()
		{
			var dialog = new Gtk.FileChooserDialog("Open File",
			                                       this,
			                                       Gtk.FileChooserAction.OPEN,
			                                       null);
			dialog.run();
		}
		
		private void new_presentation()
		{
			var Window = new Window();
			Window.show_all();
		}
		
		private Gtk.Toolbar create_toolbar()
		{
			var toolbar = new Gtk.Toolbar();
			
			var newButton = new Gtk.ToolButton.from_stock("gtk-new");
			toolbar.insert(newButton, 0);
			
			return toolbar;
		}
		
		// menu bar creation
		private Gtk.MenuBar create_menu_bar()
		{
			var menubar = new Gtk.MenuBar();
			
			menubar.append(create_file_menu());
			
			return menubar;
		}
		
		private Gtk.MenuItem create_file_menu()
		{
			var menuItem = new Gtk.MenuItem.with_label("File");
			var menu = new Gtk.Menu();
			
			var newItem = new Gtk.MenuItem.with_label("New");
			var newMenu = new Gtk.Menu();
			var newPres = new Gtk.MenuItem.with_label("Presentation");
			newPres.activate.connect(new_presentation);
			var newTheme = new Gtk.MenuItem.with_label("Theme");
			newMenu.append(newPres);
			newMenu.append(newTheme);
			newItem.set_submenu(newMenu);
			menu.append(newItem);
			
			var openItem = new Gtk.MenuItem.with_label("Open");
			openItem.activate.connect(show_open_dialog);
			openItem.set_accel_path("<-Document>/File/Open");
			Gtk.AccelMap.add_entry("<-Document>/File/Open",
			                       Gdk.keyval_from_name("o"),
			                       Gdk.ModifierType.CONTROL_MASK);
			menu.append(openItem);
			
			menuItem.set_submenu(menu);
			
			return menuItem;
		}
	}
}