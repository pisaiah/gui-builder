module main

import iui as ui
import math

fn set_bars(mut win ui.Window) {
    mut bar := win.bar
    mut item := ui.menuitem('New')
    
    arr := ['Label', 'Button', 'Textbox', 'Selector', 'Tree', 'Checkbox', 'Menubar']
    for el in arr {
        mut itemb := ui.menuitem('ui.' + el)
        itemb.set_click(nm_click)
        item.add_child(itemb)
    }
    bar.add_child(item)
}

fn nm_click(mut win ui.Window, item ui.MenuItem) {
    win.extra_map['sel-type'] = item.text
    create_new_com(mut win)
}

fn nb_click(mut win ui.Window, this ui.Button) {
	mut mod := ui.modal(win, 'Choose Type for new Component')
	mod.needs_init = false

	mut sel := ui.selector(win, 'Select Type of Component')
	sel.set_bounds(30, 20, 300, 30)

	arr := ['Label', 'Button', 'Textbox', 'Selector', 'Tree', 'Checkbox', 'Menubar']
	for el in arr {
		sel.items << ' '.repeat(20) + 'ui.' + el + ' '.repeat(20)
	}
	sel.set_change(sel_change)
	mod.add_child(sel)

	mut can := ui.button(win, 'Create')
	can.set_bounds(195, 260, 100, 25)
	can.set_click(fn (mut win ui.Window, this ui.Button) {
		win.components = win.components.filter(mut it !is ui.Modal)
		create_new_com(mut win)
	})
	mod.add_child(can)

	win.add_child(mod)
}


fn create_new_com(mut win ui.Window) {
	mut frame := get_frame(mut win)
	typ := win.extra_map['sel-type']

	clear_old(mut win, true)
	if typ == 'ui.Button' {
		mut btn := ui.button(win, 'A Button')
		btn.set_pos(20, 20)
		btn.draw_event_fn = com_draw_event

		load_details(mut win, btn)
		btn.pack()
		frame.children << btn
	} else if typ == 'ui.Label' {
		mut btn := ui.label(win, 'A Label')
		btn.set_pos(20, 20)
		load_details(mut win, btn)
		btn.draw_event_fn = com_draw_event

		btn.pack()
		frame.children << btn
	} else if typ == 'ui.Textbox' {
		mut btn := ui.textbox(win, 'A Textbox')
		btn.set_pos(20, 20)
		load_details(mut win, btn)
		btn.draw_event_fn = com_draw_event
		btn.set_bounds(20, 20, 100, 25)

		frame.children << btn
	} else if typ == 'ui.Selector' {
		mut btn := ui.selector(win, 'Choose Me')
		btn.items << 'Test Item!'
		btn.set_pos(20, 20)
		load_details(mut win, btn)
		btn.draw_event_fn = com_draw_event
		btn.set_bounds(20, 20, 100, 25)

		frame.children << btn
	} else if typ == 'ui.Menubar' {

        mut bar := ui.menubar(win, win.theme)
        bar.draw_event_fn = com_draw_event
        load_details(mut win, bar)

        frame.bar = bar
        frame.children << bar

	} else if typ == 'ui.Checkbox' {
		mut btn := ui.checkbox(win, 'Checkmate!')
		btn.set_pos(20, 20)
		load_details(mut win, btn)
		btn.draw_event_fn = com_draw_event
		btn.set_bounds(20, 20, 100, 25)
		frame.children << btn
	}
}

fn com_draw_event(mut win ui.Window, com &ui.Component) {
	if com.is_mouse_rele {
		clear_old(mut win, true)
		load_details(mut win, com)
        if mut com is ui.Menubar {
            com.is_mouse_rele = false
        }
    }

	if com.is_mouse_down {
		mut this := *com
		mut frame := get_frame(mut win)

        if !(com is ui.Menubar) {
            this.x = math.min( ((win.mouse_x/10) * 10) - frame.x - (this.width/2), frame.width - this.width)
            this.y = math.min( ((win.mouse_y/10) * 10) - frame.y - title_height - (this.height/2),
                    frame.height - this.height - title_height)
            
            this.x = math.max(0, this.x)
            this.y = math.max(0, this.y)
        }
	}
}

fn sel_change(mut win ui.Window, com ui.Select, old_val string, new_val string) {
	trim := new_val.trim_space()
	ui.debug('OLD: ' + old_val + ', NEW: ' + trim)

	win.extra_map['sel-type'] = trim
}