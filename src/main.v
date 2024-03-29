module main

import iui as ui
import os

@[heap]
struct App {
mut:
	win        &ui.Window
	dp         &ui.DesktopPane
	mframe     &ui.InternalFrame
	selected   voidptr
	output     []string
	outbox     &ui.Textbox
	kids       []ui.Component
	tik        int
	do_refresh bool
}

fn main() {
	// Create Window
	mut window := ui.Window.new(
		title: 'GUI Builder - Alpha Test Demo'
		width: 640
		height: 480
	)

	mut dp := ui.DesktopPane.new()

	mut app := &App{
		win: window
		dp: dp
		mframe: unsafe { nil }
		output: ['// Hello world']
		outbox: ui.Textbox.new()
		do_refresh: true
	}

	mut bar := ui.Menubar.new()

	bar.add_child(ui.MenuItem.new(
		text: 'File'
		children: [
			ui.MenuItem.new(
				text: 'Save As..'
			),
			ui.MenuItem.new(
				text: 'Run..'
				click_event_fn: app.run_out
			),
		]
	))

	bar.add_child(ui.MenuItem.new(
		text: 'New'
		children: [
			ui.MenuItem.new(
				text: 'Menubar'
				click_event_fn: app.new_item_click
			),
			ui.MenuItem.new(
				text: 'MenuItem'
				click_event_fn: app.new_item_click
			),
		]
	))

	bar.add_child(ui.MenuItem.new(
		text: 'Help'
		children: [
			ui.MenuItem.new(
				text: 'About iUI'
			),
		]
	))

	window.bar = bar

	window.set_theme(ui.theme_ocean())

	app.make_icons()

	mut f := ui.InternalFrame.new(
		text: 'Window Preview'
		bounds: ui.Bounds{0, 0, 350, 300}
	)
	app.mframe = f

	// f.add_child(pb)
	dp.add_child(f)

	app.output_frame()

	mut p := ui.Panel.new(
		layout: ui.BorderLayout.new()
	)

	p.add_child_with_flag(dp, ui.borderlayout_center)

	window.add_child(p)

	// Start GG / Show Window
	window.run()
}

fn (mut app App) make_btns() &ui.Panel {
	mut pa := ui.Panel.new()
	return pa
}

fn (mut app App) btn_click(mut e ui.MouseEvent) {
	app.new_frame(e.target.text.int() + 4)
}

fn (mut app App) new_frame(img_id int) {
	i := app.dp.children.len - 1
	mut frame := ui.InternalFrame.new(text: 'Frame #${i}')

	frame.set_x(360 + i * 20)
	frame.set_y(i * 32)
	frame.z_index = i + 1
	frame.height = 150

	// frame.add_child(sv)
	app.dp.add_child(frame)
}

fn (mut app App) output_frame() {
	mut frame := ui.InternalFrame.new(text: 'Code Preview')

	frame.set_x(360)
	frame.set_y(0)
	frame.width = 270
	frame.height = 250

	app.outbox.subscribe_event('draw', fn [mut app] (mut e ui.DrawEvent) {
		e.target.width = e.target.parent.width

		if e.target.height < e.target.parent.height {
			e.target.height = e.target.parent.height
		}

		if app.win.second_pass == 1 {
			app.do_refresh = true
		}

		if app.do_refresh {
			app.refresh_out()
		}
	})

	mut sv := ui.ScrollView.new(view: app.outbox)

	frame.add_child(sv)

	app.dp.add_child(frame)
}

fn (mut app App) refresh_out() {
	mut out := []string{}

	out << '// Generated by GUI Builder'
	out << '// Updated: ${app.win.last_update}'
	out << 'import iui as ui'
	out << "mut win := ui.Window.new(title: 'GUI Builder Out', width: 640, height: 480)"

	// out << '// ui body start'

	// dump(app.win.second_pass)
	for mut kid in app.kids {
		out << '// ${kid}'

		if mut kid is ui.Menubar {
			out << 'mut bar := ui.Menubar.new()'

			for mut cid in kid.children {
				out << 'mut menuitem_${cid.id} := ui.MenuItem.new('
				out << '	text: \'${cid.text}\'  '

				if cid.children.len > 0 {
					out << '	children: ['

					for mut cid2 in cid.children {
						out << '		ui.MenuItem.new('
						out << '			text: \'${cid2.text}\'  '
						out << '		)'
					}
					out << '	]'
				}

				out << ')'
				out << 'bar.add_child(menuitem_${cid.id})'
			}
			out << 'win.bar = bar'
		}

		// out << '${kid}'
	}

	// out << '// ui body end'
	out << 'win.gg.run()'

	app.outbox.lines = out
	app.do_refresh = false
}

fn (mut app App) make_icons() {
}

fn (mut app App) run_out(mut win ui.Window, item ui.MenuItem) {
	temp := os.join_path(os.temp_dir(), 'guibuilder-testing.v')
	os.write_file(temp, app.outbox.lines.join('\n')) or { panic(err) }

	os.execute('v run ${temp}')
}

fn (mut app App) new_item_click(mut win ui.Window, item ui.MenuItem) {
	dump('item click ${item.text}')

	if item.text == 'Menubar' {
		// todo: add menubar api (window.bar equiv) to internalframe
		mut bar := ui.Menubar.new()

		bar.subscribe_event('draw', fn (mut e ui.DrawEvent) {
			e.target.width = e.target.parent.width - 10
		})

		app.kids << bar
		app.mframe.add_child(bar)
		app.make_config_frame(mut bar, item.text)
	}
}

fn (mut app App) make_config_frame(mut c ui.Menubar, t string) {
	mut frame := ui.InternalFrame.new(text: 'Menubar')

	frame.set_x(360)
	frame.set_y(32)
	frame.height = 150
	frame.z_index = app.dp.children.len + 1

	mut p := ui.Panel.new(layout: ui.BoxLayout.new(ori: 1))

	mut btn := ui.Button.new(text: 'Add Child')

	btn.subscribe_event('mouse_up', fn [mut c, mut app] (mut e ui.MouseEvent) {
		mut item := ui.MenuItem.new(
			text: 'An Item'
		)

		item.id = '${app.tik}'
		app.tik += 1

		item.subscribe_event('mouse_up', fn [mut app, mut item] (mut e ui.MouseEvent) {
			app.make_config_menuitem(mut item, 'MenuItem')
		})

		c.add_child(item)
	})

	p.add_child(btn)

	mut sv := ui.ScrollView.new(view: p)

	frame.add_child(sv)

	app.dp.add_child(frame)
}

fn (mut app App) make_config_menuitem(mut c ui.MenuItem, t string) {
	for mut kid in app.dp.children {
		dump(kid.text)
		if kid.id.len > 0 && kid.id == 'for-menuitem-${c.id}' {
			return
		}
	}

	dump(c)

	mut frame := ui.InternalFrame.new(text: 'MenuItem')
	frame.id = 'for-menuitem-${c.id}'

	frame.set_x(360)
	frame.set_y(32)
	frame.height = 150
	frame.z_index = app.dp.children.len + 1

	mut p := ui.Panel.new(layout: ui.BoxLayout.new(ori: 1))

	mut tf := ui.TextField.new(text: c.text)
	tf.set_text_change(fn (a voidptr, b voidptr) {
	})

	tf.subscribe_event('before_text_change', fn [mut c] (mut e ui.TextChangeEvent) {
		c.text = e.target.text
	})

	// tf.bind_to(&c.text)

	mut btn := ui.Button.new(text: 'Add Child')

	btn.subscribe_event('mouse_up', fn [mut c] (mut e ui.MouseEvent) {
		mut item := ui.MenuItem.new(text: 'An Item')
		c.add_child(item)
	})

	p.add_child(ui.Titlebox.new(text: 'Text', children: [tf]))
	p.add_child(ui.Titlebox.new(text: 'Children', children: [btn]))

	mut sv := ui.ScrollView.new(view: p)

	frame.add_child(sv)

	app.dp.add_child(frame)
}
