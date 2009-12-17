namespace Ease
{
	public class TextElement : Element
	{
		public string text { get; set; }
		public Clutter.Color color;
		public string font_name { get; set; }
		public uint font_size { get; set; }
		
		public override void print_representation()
		{
			stdout.printf("\t\t\tText Element:\n");
			base.print_representation();
			stdout.printf("\t\t\t\tease_name: %s\n", ease_name);
			stdout.printf("\t\t\t\t     text: %s\n", text);
			stdout.printf("\t\t\t\tfont_name: %s\n", font_name);
			stdout.printf("\t\t\t\tfont_size: %u\n", font_size);
		}
		
		public override Clutter.Actor presentation_actor() throws GLib.Error
		{
			var actor = new Clutter.Text();
			set_actor_base_properties(actor);
			actor.use_markup = true;
			actor.line_wrap = true;
			actor.color = this.color;
			actor.text = this.text;
			actor.font_name = this.font_name + " " + this.font_size.to_string();
			return actor;
		}
	}
}