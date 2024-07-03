require 'gtk3'
require 'shellwords'
require 'gdk_pixbuf2'


class SimpleEditor
  def initialize
    @window = Gtk::Window.new
    @window.set_title("DiskForensix")
    @window.set_default_size(800, 600)
    @window.signal_connect("destroy") { Gtk.main_quit }

    vbox = Gtk::Box.new(:vertical)
    @window.add(vbox)

    create_menu(vbox)

    title_label = Gtk::Label.new("DiskForensix")
    title_label.set_markup("<span font_desc='20'>DiskForensix</span>")
    vbox.pack_start(title_label, expand: false, fill: false, padding: 10)

    button_box = Gtk::Box.new(:horizontal, 10)
    vbox.pack_start(button_box, expand: false, fill: false, padding: 10)

    @create_image_button = Gtk::Button.new(label: "Create Image")
    @create_image_button.set_size_request(150, 40)  # Adjust button size
    @create_image_button.signal_connect("clicked") { open_image_creation_dialog }
    button_box.pack_start(@create_image_button, expand: false, fill: false, padding: 5)
    button_box.set_halign(:center)  # Center the button in the horizontal box
    button_box.set_valign(:center)

    @text_view = Gtk::TextView.new
    @text_view.set_wrap_mode(:word)

    @scrolled_window = Gtk::ScrolledWindow.new
    @scrolled_window.add(@text_view)
    @scrolled_window.set_policy(:automatic, :automatic)

    vbox.pack_start(@scrolled_window, expand: true, fill: true, padding: 10)

    # Open Image Button
    @open_image_button = Gtk::Button.new(label: "Open Image")
    @open_image_button.set_size_request(150, 40)  # Adjust button size
    @open_image_button.signal_connect("clicked") { open_image_dialog }

    button_box.pack_start(@open_image_button, expand: false, fill: false, padding: 5)

    version_label = Gtk::Label.new("Version 1.0.0")
    version_label.set_margin_top(10)
    vbox.pack_end(version_label, expand: false, fill: false, padding: 10)

    @window.show_all
  end

  def create_menu(vbox)
    menu_bar = Gtk::MenuBar.new
    file_menu = Gtk::Menu.new
    file_item = Gtk::MenuItem.new(label: "File")
    file_item.set_submenu(file_menu)

    exit_item = Gtk::MenuItem.new(label: "Exit")
    exit_item.signal_connect("activate") { Gtk.main_quit }
    file_menu.append(exit_item)

    menu_bar.append(file_item)

    # Tool Menu
    tool_menu = Gtk::Menu.new
    tool_item = Gtk::MenuItem.new(label: "Tool")
    tool_item.set_submenu(tool_menu)

    create_image_item = Gtk::MenuItem.new(label: "Create Image")
    create_image_item.signal_connect("activate") { open_image_creation_dialog }
    tool_menu.append(create_image_item)

    show_hex_dump_item = Gtk::MenuItem.new(label: "Show Hex Dump")
    show_hex_dump_item.signal_connect("activate") { open_image_dialog }
    tool_menu.append(show_hex_dump_item)


menu_bar.append(tool_item)

# Help Menu
help_menu = Gtk::Menu.new
help_item = Gtk::MenuItem.new(label: "Help")
help_item.set_submenu(help_menu)

about_item = Gtk::MenuItem.new(label: "About")
about_item.signal_connect("activate") { open_about_dialog }
help_menu.append(about_item)

menu_bar.append(help_item)

vbox.pack_start(menu_bar, expand: false, fill: false, padding: 0)
end

def open_about_dialog
about_dialog = Gtk::AboutDialog.new
about_dialog.set_program_name("DiskForensix")
about_dialog.set_version("1.0.0")
about_dialog.set_license("GNU General Public License v3.0")
about_dialog.set_comments("A tool for forensic image creation and hex dumping.")
about_dialog.set_website("https://github.com/Ahmad-Rasheed-01/DiskForensix.git")
about_dialog.set_website_label("GitHub Repository")

 logo_pixbuf_path = File.expand_path('/home/master_chief/Downloads/img.jpg')  # Expand ~ to full path
 if File.exist?(logo_pixbuf_path)  # Check if the file exists

  # Load the pixbuf from the file
  original_pixbuf = GdkPixbuf::Pixbuf.new(file: logo_pixbuf_path)
    scaled_pixbuf = original_pixbuf.scale_simple(100, 100, GdkPixbuf::InterpType::BILINEAR)
    
    # Set the scaled pixbuf as the logo
    about_dialog.set_logo(scaled_pixbuf)

 else
   puts "Logo file not found at #{logo_pixbuf_path}"  # Debugging message if file is missing
 end

about_dialog.run
about_dialog.destroy
end


  def open_image_dialog
    dialog = Gtk::FileChooserDialog.new(
      title: "Select Image File",
      parent: @window,
      action: Gtk::FileChooserAction::OPEN,
      buttons: [
        [Gtk::Stock::CANCEL, Gtk::ResponseType::CANCEL],
        [Gtk::Stock::OPEN, Gtk::ResponseType::ACCEPT]
      ]
    )

    if dialog.run == Gtk::ResponseType::ACCEPT
      image_path = dialog.filename
      # Properly escape the file path
      escaped_image_path = Shellwords.escape(image_path)
      # Run xxd command and capture output
      xxd_output = `xxd #{escaped_image_path}`
      show_xxd_output(xxd_output, image_path)
    end

    dialog.destroy
  end

  def show_xxd_output(xxd_output, image_path)
    # Create a new window to show xxd output
    xxd_window = Gtk::Window.new
    xxd_window.set_title("xxd Output for #{image_path}")
    xxd_window.set_default_size(600, 400)

    vbox = Gtk::Box.new(:vertical)
    xxd_window.add(vbox)

    xxd_text_view = Gtk::TextView.new
    xxd_text_view.set_wrap_mode(:word)
    xxd_text_view.buffer.text = xxd_output

    xxd_scrolled_window = Gtk::ScrolledWindow.new
    xxd_scrolled_window.add(xxd_text_view)
    xxd_scrolled_window.set_policy(:automatic, :automatic)

    vbox.pack_start(xxd_scrolled_window, expand: true, fill: true, padding: 10)

    close_button = Gtk::Button.new(label: "Close")
    close_button.signal_connect("clicked") { xxd_window.destroy }
    vbox.pack_start(close_button, expand: false, fill: false, padding: 10)

    xxd_window.show_all
  end

  def open_image_creation_dialog
    clear_paths

    dialog = Gtk::Dialog.new(
      title: "Create Forensic Image",
      parent: @window,
      flags: :modal
    )

    dialog.set_default_size(600, 400)

    content_area = dialog.content_area
    vbox = Gtk::Box.new(:vertical, 10)
    content_area.add(vbox)

    # Centered Evidence Item Information Button
    info_button = Gtk::Button.new(label: "Add Evidence Item Information")
    info_button.set_size_request(200, 40)  # Adjust the width of the button
    info_button.signal_connect("clicked") { open_evidence_info_dialog }

    info_button_box = Gtk::Box.new(:horizontal)
    info_button_box.pack_start(info_button, expand: false, fill: false, padding: 10)
    info_button_box.set_halign(:start)
    vbox.pack_start(info_button_box, expand: false, fill: false, padding: 10)

    source_hbox = Gtk::Box.new(:horizontal, 10)
    source_label = Gtk::Label.new("Image Source:")
    @source_entry = Gtk::Entry.new
    source_browse_button = Gtk::Button.new(label: "Browse")
    source_browse_button.signal_connect("clicked") { select_source }
    source_hbox.pack_start(source_label, expand: false, fill: false, padding: 5)
    source_hbox.pack_start(@source_entry, expand: true, fill: true, padding: 5)
    source_hbox.pack_start(source_browse_button, expand: false, fill: false, padding: 5)
    vbox.pack_start(source_hbox, expand: false, fill: false, padding: 5)

    destination_hbox = Gtk::Box.new(:horizontal, 10)
    destination_label = Gtk::Label.new("Image Destination:")
    @destination_entry = Gtk::Entry.new
    destination_browse_button = Gtk::Button.new(label: "Browse")
    destination_browse_button.signal_connect("clicked") { select_destination }
    destination_hbox.pack_start(destination_label, expand: false, fill: false, padding: 5)
    destination_hbox.pack_start(@destination_entry, expand: true, fill: true, padding: 5)
    destination_hbox.pack_start(destination_browse_button, expand: false, fill: false, padding: 5)
    vbox.pack_start(destination_hbox, expand: false, fill: false, padding: 5)

    # Start Imaging Button
    @start_button = Gtk::Button.new(label: "Start Imaging")
    @start_button.set_size_request(150, 40)  # Adjust button size
    @start_button.sensitive = false
    @start_button.signal_connect("clicked") do
      dialog.response(Gtk::ResponseType::ACCEPT)
    end

    start_button_box = Gtk::Box.new(:horizontal)
    start_button_box.pack_start(@start_button, expand: false, fill: false, padding: 10)
    start_button_box.set_halign(:center)
    start_button_box.set_valign(:center)
    vbox.pack_start(start_button_box, expand: false, fill: false, padding: 10)

    dialog.signal_connect("response") do |widget, response|
      if response == Gtk::ResponseType::ACCEPT
        @source_path = @source_entry.text
        @destination_path = @destination_entry.text
        # + " [raw/dd]"
        create_forensic_image
      end
      dialog.destroy
    end

    dialog.signal_connect("destroy") do
      clear_paths
    end

    dialog.show_all
  end

  def open_evidence_info_dialog
    dialog = Gtk::Dialog.new(
      title: "Evidence Item Information",
      parent: @window,
      flags: :modal
    )

    dialog.set_default_size(400, 300)

    vbox = Gtk::Box.new(:vertical, 10)
    dialog.content_area.add(vbox)

    grid = Gtk::Grid.new
    grid.set_row_spacing(10)
    grid.set_column_spacing(10)
    vbox.pack_start(grid, expand: false, fill: false, padding: 10)

    # Case Number
    case_number_hbox = Gtk::Box.new(:horizontal, 5)
    case_number_label = Gtk::Label.new("Case Number:")
    @case_number_entry = Gtk::Entry.new
    case_number_hbox.pack_start(case_number_label, expand: false, fill: false, padding: 5)
    case_number_hbox.pack_start(@case_number_entry, expand: true, fill: true, padding: 5)
    grid.attach(case_number_hbox, 0, 0, 2, 1)

    # Evidence Number
    evidence_number_hbox = Gtk::Box.new(:horizontal, 5)
    evidence_number_label = Gtk::Label.new("Evidence Number:")
    @evidence_number_entry = Gtk::Entry.new
    evidence_number_hbox.pack_start(evidence_number_label, expand: false, fill: false, padding: 5)
    evidence_number_hbox.pack_start(@evidence_number_entry, expand: true, fill: true, padding: 5)
    grid.attach(evidence_number_hbox, 0, 1, 2, 1)

    # Examiner
    examiner_hbox = Gtk::Box.new(:horizontal, 5)
    examiner_label = Gtk::Label.new("Examiner:")
    @examiner_entry = Gtk::Entry.new
    examiner_hbox.pack_start(examiner_label, expand: false, fill: false, padding: 5)
    examiner_hbox.pack_start(@examiner_entry, expand: true, fill: true, padding: 5)
    grid.attach(examiner_hbox, 0, 2, 2, 1)

    # Unique Description
    description_hbox = Gtk::Box.new(:horizontal, 5)
    description_label = Gtk::Label.new("Unique Description:")
    @description_entry = Gtk::Entry.new
    description_hbox.pack_start(description_label, expand: false, fill: false, padding: 5)
    description_hbox.pack_start(@description_entry, expand: true, fill: true, padding: 5)
    grid.attach(description_hbox, 0, 3, 2, 1)

    # Notes
    notes_hbox = Gtk::Box.new(:horizontal, 5)
    notes_label = Gtk::Label.new("Notes:")
    @notes_entry = Gtk::Entry.new
    notes_hbox.pack_start(notes_label, expand: false, fill: false, padding: 5)
    notes_hbox.pack_start(@notes_entry, expand: true, fill: true, padding: 5)
    grid.attach(notes_hbox, 0, 4, 2, 1)

    ok_button = Gtk::Button.new(label: "OK")
    ok_button.set_size_request(100, -1)  # Adjust the width to 100 pixels

    ok_button_box = Gtk::Box.new(:horizontal)
    ok_button_box.pack_start(ok_button, expand: false, fill: false, padding: 10)

    # Center the ok_button_box within the dialog
    ok_button_box.set_halign(:center)
    ok_button_box.set_valign(:center)

    ok_button.signal_connect("clicked") { dialog.response(Gtk::ResponseType::ACCEPT) }
    vbox.pack_start(ok_button_box, expand: false, fill: false, padding: 10)

    dialog.signal_connect("response") do |widget, response|
      if response == Gtk::ResponseType::ACCEPT
        # Handle the input data as needed
        case_number = @case_number_entry.text
        evidence_number = @evidence_number_entry.text
        examiner = @examiner_entry.text
        description = @description_entry.text
        notes = @notes_entry.text

        # Append evidence information to text view
        @text_view.buffer.text = "Case Number:       #{case_number}\n" \
                                "Evidence Number:    #{evidence_number}\n" \
                                "Examiner:           #{examiner}\n" \
                                "Unique Description: #{description}\n" \
                                "Notes:              #{notes}\n" \
                                "---------------------------\n" \
                                "#{@text_view.buffer.text}"

        # Reset the entries for next use
        @case_number_entry.text = ""
        @evidence_number_entry.text = ""
        @description_entry.text = ""
        @examiner_entry.text = ""
        @notes_entry.text = ""
      end
      dialog.destroy
    end

    dialog.show_all
  end

  def select_source
    source_dialog = Gtk::FileChooserDialog.new(
      title: "Select Source",
      parent: @window,
      action: Gtk::FileChooserAction::OPEN,
      buttons: [
        [Gtk::Stock::CANCEL, Gtk::ResponseType::CANCEL],
        [Gtk::Stock::OPEN, Gtk::ResponseType::ACCEPT]
      ]
    )

    if source_dialog.run == Gtk::ResponseType::ACCEPT
      @source_path = source_dialog.filename
      @source_entry.text = @source_path
      check_paths
    end

    source_dialog.destroy
  end

  def select_destination
    destination_dialog = Gtk::FileChooserDialog.new(
      title: "Select Destination",
      parent: @window,
      action: Gtk::FileChooserAction::SAVE,
      buttons: [
        [Gtk::Stock::CANCEL, Gtk::ResponseType::CANCEL],
        [Gtk::Stock::SAVE, Gtk::ResponseType::ACCEPT]
      ]
    )

    if destination_dialog.run == Gtk::ResponseType::ACCEPT
      @destination_path = destination_dialog.filename
      @destination_entry.text = @destination_path
      check_paths
    end

    destination_dialog.destroy
  end

  def check_paths
    if @source_path && @destination_path && !@start_button&.destroyed?
      @start_button.sensitive = true
    elsif @start_button && !@start_button.destroyed?
      @start_button.sensitive = false
    end
  end

  def clear_paths
    @source_path = nil
    @destination_path = nil
    if @start_button && !@start_button.destroyed?
      @start_button.sensitive = false
    end
  end

  def create_forensic_image
    if @source_path && @destination_path
      create_image_command = "dd if='#{@source_path}' of='#{@destination_path}' bs=4M conv=sync,noerror"
      @text_view.buffer.text = "Creating forensic image...\n\n" + @text_view.buffer.text
      Thread.new do
        system(create_image_command)
        GLib::Idle.add do
          @text_view.buffer.text = "Forensic image created successfully. #{@destination_path}\n" + @text_view.buffer.text
          false
        end
      end
    else
      @text_view.buffer.text = "Source or destination path not selected.\n" + @text_view.buffer.text
    end
  end
end

Gtk.init
SimpleEditor.new
Gtk.main
