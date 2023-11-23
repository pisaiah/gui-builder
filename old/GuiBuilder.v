module main

import iui as ui
import v.util.version { full_v_version }
import os
import gg
import math
import gx

const (
	version      = '0.1'
	title_height = 21
	pos_inc      = 10
)

struct Frame {
	ui.Component_A
mut:
	win      &ui.Window
	bg       ui.Image
	bar      ui.Menubar
	children []ui.Component
}

fn (mut this Frame) draw() {
	bord := gx.rgb(195, 195, 195)
	this.win.draw_bordered_rect(this.x, this.y, this.width, this.height, 2, gx.rgb(246,
		245, 244), bord)
	this.win.draw_bordered_rect(this.x + 1, this.y + 1, this.width - 2, title_height - 1,
		2, gx.white, gx.white)
	ui.draw_with_offset(mut this.bg, (this.x + this.width) - this.bg.width, this.y)

	for mut kid in this.children {
		kid.draw_event_fn(mut this.win, &kid)
		if mut kid is ui.Menubar {
			kid.width = this.width - 2
			kid.height = 25
			ui.draw_with_offset(mut kid, this.x + 1, this.y + title_height)
			continue
		}
		ui.draw_with_offset(mut kid, this.x, this.y + title_height)
	}
}

[console]
fn main() {
	mut win := ui.window(ui.get_system_theme(), 'GUI Builder ' + version, 800, 500)

	win.bar = ui.menubar(win, win.theme)

	mut help := ui.menuitem('Help')
	mut about := ui.menuitem('About iUI')
	mut abut := ui.menuitem('About GUI Builder')
	abut.set_click(about_click)

	set_bars(mut win)

	help.add_child(about) // Add About item to Help menu
	help.add_child(abut)
	win.bar.add_child(help) // Add Help menu to Menubar

	imgf := $embed_file('test.png')
	mut img := ui.image_from_byte_array_with_size(mut win, imgf.to_bytes(), 98, 22)
	img.pack()

	mut frame := &Frame{
		win: mut win
		bg: img
		width: 500
		height: 350
	}
	frame.win = win
	frame.set_pos(40, 40)
	frame.draw_event_fn = win_draw
	win.add_child(frame)
	img.z_index = -1
	frame.z_index = 2

	clear_old(mut win, false)

	mut logoim := win.gg.create_image(os.resource_abs_path('logo.png'))
	mut logo := ui.image(win, logoim)
	logo.set_bounds(22, 24, 456, 65)
	logo.pack()
	logo.draw_event_fn = fn (mut win ui.Window, com &ui.Component) {
		mut this := *com
		size := gg.window_size()
		this.x = 0 // size.width - this.width
		this.y = size.height - this.height
	}
	win.add_child(logo)

	win.gg.run()
}

fn win_draw(mut win ui.Window, com &ui.Component) {
	if com.is_mouse_down {
		if win.extra_map['a'] == '-' {
			win.extra_map['a'] = com.x.str()
			win.extra_map['b'] = com.y.str()
		}

		mut off := win.click_x - win.extra_map['a'].int()
		mut offy := win.click_y - win.extra_map['b'].int()
		if offy < title_height {
			mut this := *com
			this.x = win.mouse_x - off
			this.y = win.mouse_y - offy
			return
		}
	} else {
		win.extra_map['a'] = '-'
	}

	mut this := *com
	if mut this is Frame {
		mut found := false
		for mut kid in this.children {
			if mut kid is ui.Menubar {
				kid.width = this.width - 2
				kid.height = 25
			}
			if this.is_mouse_down {
				if ui.point_in(mut kid, win.click_x - this.x, win.click_y - (this.y + title_height)) {
					kid.is_mouse_down = true
					this.is_mouse_down = false

					found = true
				} else {
					kid.is_mouse_down = false
				}
			}
			if this.is_mouse_rele {
				if ui.point_in(mut kid, win.mouse_x - this.x, win.mouse_y - (this.y + title_height)) {
					kid.is_mouse_down = false
					kid.is_mouse_rele = true
					this.is_mouse_rele = false
					found = true
				} else {
					kid.is_mouse_down = false
					kid.is_mouse_rele = false
				}
			}
		}
		if !found {
			this.is_mouse_down = false
			this.is_mouse_rele = false
		}
	}
}

fn on_click(mut win ui.Window, btn ui.Button) {
	println('Button clicked!')

	mut lbl := ui.label(win, 'Hello!')

	lbl.set_pos(5, 5)
	lbl.pack()
	lbl.set_click(lbl_click)

	for mut com in win.components {
		if mut com is Frame {
			com.children << lbl
			return
		}
	}
}

fn lbl_click(mut win ui.Window, this ui.Label) {
	println('BTN CLICK')
}

fn clear_old(mut win ui.Window, clear bool) {
	mut size := gg.window_size()
	if clear {
		win.components = win.components.filter(it.x < (size.width - 200))
	}

	mut nb := ui.button(win, 'New Component')
	nb.set_pos(470, 32)
	nb.set_bounds(470, 32, 200 - 5, 30)
	nb.draw_event_fn = draw_ev
	nb.set_click(nb_click)
	nb.z_index = 1
	win.add_child(nb)

	mut details := ui.label(win, 'Details:')
	details.draw_event_fn = draw_details
	details.set_pos(500, 70)
	details.pack()
	win.add_child(details)
}

fn draw_details(mut win ui.Window, com &ui.Component) {
	size := gg.window_size()
	win.draw_bordered_rect(com.x - 5, 0, size.width - com.x + 5, size.height, 1, win.theme.textbox_background,
		win.theme.textbox_border)
	draw_ev(mut win, com)
}

fn get_frame(mut win ui.Window) &Frame {
	for mut frame in win.components {
		if mut frame is Frame {
			return frame
		}
	}
	return &Frame{
		win: 0
	}
}

struct Store {
	ui.Component_A
mut:
	com ui.Component
}

fn (mut this Store) draw() {
}

fn load_details(mut win ui.Window, com &ui.Component) {
	for mut details in win.components {
		if mut details is ui.Label {
			if details.text.starts_with('Details:') {
				mut btn := *com
				is_bar := btn is ui.Menubar

				details.text = 'Details:'
				details.draw_event_fn = fn (mut win ui.Window, com &ui.Component) {
					mut this := *com
					mut size := gg.window_size()

					this.text = 'hello'
					for mut comm in win.components {
						if mut comm is Store {
							btn := comm.com
							is_bar := btn is ui.Menubar
							if is_bar {
								this.text = 'Details:\n'
							} else {
								this.text = 'Details:\n' + 'x: ' + btn.x.str() + '\ny: ' +
									btn.y.str() + '\n\nText:'
							}
						}
					}

					bar := win.show_menu_bar
					mut oy := 0
					if bar {
						oy = 25
					}
					wid := 200
					this.x = size.width - wid
					win.draw_bordered_rect(this.x - 5, oy, size.width - this.x + 5, size.height - oy,
						1, win.theme.textbox_background, win.theme.textbox_border)
				}
				details.z_index = -4

				mut found := false
				for mut comm in win.components {
					if mut comm is Store {
						comm.com = btn
						found = true
					}
				}
				if !found {
					mut store := Store{
						com: btn
					}
					win.add_child(store)
				}

				if !is_bar {
					mut txtb := ui.textbox(win, btn.text)
					txtb.set_bounds(100, 150, 70, 20)
					txtb.draw_event_fn = draw_ev_2
					win.add_child(txtb)
				}

				make_text_input(mut win, 100, 180, 'Event Fn: Draw', '')
				make_text_input(mut win, 100, 230, 'Event Fn: After Draw', '')
			}
		}
	}
}

fn make_text_input(mut win ui.Window, x int, y int, label string, text string) {
	mut clbl := ui.label(win, label)
	clbl.set_pos(x, y)
	clbl.draw_event_fn = draw_ev
	clbl.pack()

	mut txtc := ui.textbox(win, text)
	txtc.set_bounds(x, y + 20, 70, 20)
	txtc.draw_event_fn = draw_ev

	win.add_child(clbl)
	win.add_child(txtc)
}

fn draw_ev(mut win ui.Window, com &ui.Component) {
	mut this := *com
	mut size := gg.window_size()
	this.x = (size.width - 200) + this.scroll_i // Button doesn't use scroll_i, so lets use it.
	if mut this is ui.Textbox {
		txt := ui.text_width(win, this.text + 'Ab')
		this.width = math.max(190, txt)
	}
}

fn draw_ev_2(mut win ui.Window, com &ui.Component) {
	mut this := *com
	mut size := gg.window_size()
	this.x = (size.width - 200) + this.scroll_i // Button doesn't use scroll_i, so lets use it.
	if mut this is ui.Textbox {
		txt := ui.text_width(win, this.text + 'Ab')
		this.width = math.max(190, txt)

		mut store := find_store(mut win)
		store.com.text = this.text
	}
}

fn find_store(mut win ui.Window) &Store {
	for mut com in win.components {
		if mut com is Store {
			return com
		}
	}
	return &Store{
		com: &ui.Component_A{}
	}
}

fn about_click(mut win ui.Window, item ui.MenuItem) {
	mut about := ui.modal(win, 'About GUI Builder')
	mut lbl := ui.label(win, "Isaiah's GUI Builder for V.\nVersion: " + version +
		'\n\nCompiled with ' + full_v_version(false))
	lbl.set_pos(145, 125)
	about.add_child(lbl)

	mut logo := win.gg.create_image(os.resource_abs_path('logo.png'))
	mut img := ui.image(win, logo)
	img.set_bounds(22, 24, 456, 65)
	img.pack()

	about.add_child(img)

	mut copy := ui.label(win, 'Copyright © 2021-2022 Isaiah.\nAll Rights Reserved.')
	copy.set_pos(145, 220)
	about.add_child(copy)

	win.add_child(about)
}
