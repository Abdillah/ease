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
 * A window for editing an Ease {@link Document}
 *
 * An EditorWindow contains several widgets: a {@link MainToolbar}, an
 * {@link EditorEmbed}, a {@link SlideButtonPanel}, and assorted other
 * controls. The window is linked to a {@link Document}, and all changes
 * are made directly to that object.
 */
public class Ease.EditorWindow : Gtk.Window
{
	// interface elements
	public EditorEmbed embed;
	public MainToolbar main_toolbar;
	public Gtk.HBox slides;
	public SlidePane pane_slide;
	
	// zoom
	public ZoomSlider zoom_slider;

	// the player for this window
	private Player player;
	
	public Document document;
	public Slide slide;
	
	private Inspector inspector;
	
	// the UndoController for this window
	private UndoController undo;
	
	// interface variables
	public bool inspector_shown { get; set; }
	public bool slides_shown { get; set; }
	
	// constants
	private int[] ZOOM_LEVELS = {10, 25, 33, 50, 66, 75, 100, 125, 150,
	                             200, 250, 300, 400};
	private const int ZOOM_COUNT = 13;

	/**
	 * Creates a new EditorWindow.
	 * 
	 * An EditorWindow includes a {@link MainToolbar}, an
	 * {@link EditorEmbed}, a {@link SlidePane}, a menu bar, and other
	 * interface elements.
	 *
	 * @param node The initial XML node to begin with.
	 */
	public EditorWindow(Document doc)
	{
		title = "Ease";
		set_default_size(1024, 768);
		
		document = doc;
		
		// slide display
		var slides_win = new SlideButtonPanel(document, this);
		
		// undo controller
		undo = new UndoController();
		
		// the inspector
		inspector = new Inspector();
		
		// main editor
		embed = new EditorEmbed(document, this);
		
		// assemble middle contents			
		var hbox = new Gtk.HBox(false, 0);
		var hpaned = new Gtk.HPaned();
		hpaned.pack1(slides_win, false, false);
		hpaned.pack2(embed, true, true);
		hbox.pack_start(hpaned, true, true, 0);
		hbox.pack_start(inspector, false, false, 0);
		
		// assemble window contents
		var vbox = new Gtk.VBox(false, 0);
		vbox.pack_start(create_menu_bar(), false, false, 0);
		main_toolbar = new MainToolbar();
		vbox.pack_start(main_toolbar, false, false, 0);
		vbox.pack_start(new Gtk.HSeparator(), false, false, 0);
		vbox.pack_start(hbox, true, true, 0);
		vbox.pack_end(create_bottom_bar(), false, false, 0);
		
		// final window setup
		add(vbox);
		show_all();
		embed.show();
		inspector.hide();
		inspector_shown = false;
		slides_shown = true;
		
		// USER INTERFACE SIGNALS
		
		// toolbar
		
		// show and hide inspector
		main_toolbar.inspector.clicked.connect(() => {
			if (inspector_shown)
			{
				inspector.hide();
			}
			else
			{
				inspector.show();
			}
			inspector_shown = !inspector_shown;
		});
		
		// show and hide slides
		main_toolbar.slides.clicked.connect(() => {
			if (slides_shown)
			{
				slides.hide();
			}
			else
			{
				slides.show();
			}
			slides_shown = !slides_shown;
		});

		// make a new presentation
		main_toolbar.new_presentation.clicked.connect(Main.show_welcome);

		// open a file
		main_toolbar.open.clicked.connect(() => OpenDialog.run());
		
		// save file
		main_toolbar.save.clicked.connect(() => {
			try { JSONParser.document_write(document); }
			catch (GLib.Error e)
			{
				var dialog = new Gtk.MessageDialog(null,
					                               Gtk.DialogFlags.NO_SEPARATOR,
					                               Gtk.MessageType.ERROR,
					                               Gtk.ButtonsType.CLOSE,
					                               _("Error saving: %s"),
					                               e. message);
			
				dialog.title = _("Error Saving");
				dialog.border_width = 5;
				dialog.run();
			}
		});
		
		// play presentation
		main_toolbar.play.clicked.connect(() => {
			player = new Player(document);
		});
		
		// undo and redo
		main_toolbar.undo.clicked.connect(() => {
			undo.undo();
			update_undo();
			embed.slide_actor.relayout();
			embed.reposition_group();
		});
		
		// TODO: export HTML in a proper place
		main_toolbar.fonts.clicked.connect(() => {
			document.export_to_html(this);
		});
		
		// change the embed's zoom when the zoom slider is moved
		zoom_slider.value_changed.connect(() => {
			embed.set_zoom((float)zoom_slider.get_value());
		});

		hide.connect(() => Main.remove_window(this));
		
		load_slide(0);
		update_undo();
	}
	
	/**
	 * Load a slide into the main {@link EditorEmbed}.
	 *
	 * @param filename The index of the slide.
	 */
	public void load_slide(int index)
	{
		slide = document.slides.get(index);
		
		// update ui elements for this new slide
		inspector.slide = slide;
		embed.set_slide(slide);
	}
	
	/**
	 * Add the most recent action to the {@link UndoController}.
	 *
	 * @param action The new {@link UndoAction}.
	 */
	public void add_undo_action(UndoAction action)
	{
		undo.add_action(action);
		update_undo();
	}
	
	private void update_undo()
	{
		main_toolbar.undo.sensitive = undo.can_undo();
		main_toolbar.redo.sensitive = false;
	}
	
	// signal handlers
	private void show_open_dialog()
	{
		var dialog = new Gtk.FileChooserDialog(_("Open File"),
		                                       this,
		                                       Gtk.FileChooserAction.OPEN,
		                                       null);
		dialog.run();
	}
	
	private void new_presentation()
	{
		//var window = new EditorWindow("../../../../Examples/Example.ease/");
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
		/* TODO : use mnemonics */
		var menuItem = new Gtk.MenuItem.with_label(_("File"));
		var menu = new Gtk.Menu();
		
		var newItem = new Gtk.MenuItem.with_label(_("New"));
		var newMenu = new Gtk.Menu();
		var newPres = new Gtk.MenuItem.with_label(_("Presentation"));
		newPres.activate.connect(new_presentation);
		var newTheme = new Gtk.MenuItem.with_label(_("Theme"));
		var Quit = new Gtk.MenuItem.with_label(_("Quit"));
		Quit.activate.connect( Gtk.main_quit );

		newMenu.append(newPres);
		newMenu.append(newTheme);
		newItem.set_submenu(newMenu);
		menu.append(newItem);
		
		var openItem = new Gtk.MenuItem.with_label(_("Open"));
		openItem.activate.connect(show_open_dialog);
		openItem.set_accel_path("<-Document>/File/Open");
		Gtk.AccelMap.add_entry("<-Document>/File/Open",
		                       Gdk.keyval_from_name("o"),
		                       Gdk.ModifierType.CONTROL_MASK);
		menu.append(openItem);
		menu.append(Quit);
		menuItem.set_submenu(menu);
		
		return menuItem;
	}
	
	private Gtk.Alignment create_bottom_bar()
	{
		var hbox = new Gtk.HBox(false, 5);
		
		// create zoom slider
		zoom_slider = new ZoomSlider(new Gtk.Adjustment(100, 10, 400, 10,
		                                                50, 50), ZOOM_LEVELS);
		zoom_slider.width_request = 200;
		zoom_slider.value_pos = Gtk.PositionType.RIGHT;
		zoom_slider.digits = 0;
		
		// put it all together
		hbox.pack_start(zoom_slider, false, false, 0);
		
		var vbox = new Gtk.VBox(false, 0);
		vbox.pack_start(new Gtk.HSeparator(), false, false, 0);
		vbox.pack_start(hbox, true, true, 2);
		
		var align = new Gtk.Alignment(1, 1, 1, 1);
		align.add(vbox);
		return align;
	}
}

