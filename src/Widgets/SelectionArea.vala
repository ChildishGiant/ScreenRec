/*
 * Copyright (c) 2014-2016 Fabio Zaramella <ffabio.96.x@gmail.com>
 *               2017 elementary LLC. (https://elementary.io)
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License version 3 as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA
 */

namespace Screenshot.Widgets {
    public class SelectionArea : Granite.Widgets.CompositedWindow {
        public signal void captured ();
        public signal void cancelled ();

        private Gdk.Point start_point;

        private bool dragging = false;

        construct {
            type = Gtk.WindowType.POPUP;
        }

        public SelectionArea () {
            stick ();
            set_resizable (true);
            set_deletable (false);
            set_skip_taskbar_hint (true);
            set_skip_pager_hint (true);
            set_keep_above (true);

            var display = Gdk.Display.get_default ();
            Gdk.Monitor monitor = display.get_primary_monitor ();
            Gdk.Rectangle geom = monitor.get_geometry ();
            set_default_size (geom.width, geom.height);
        }

        public override bool button_press_event (Gdk.EventButton e) {
            if (dragging || e.button != 1) {
                return true;
            }

            dragging = true;

            start_point.x = (int)e.x_root;
            start_point.y = (int)e.y_root;

            return true;            
        }

        public override bool button_release_event (Gdk.EventButton e) {
            if (!dragging || e.button != 1) {
                return true;
            }

            dragging = false;
            captured ();

            return true;            
        }

        public override bool motion_notify_event (Gdk.EventMotion e) {
            if (!dragging) {
                return true;
            }

            int x = start_point.x;
            int y = start_point.y;

            int width = (x - (int)e.x_root).abs ();
            int height = (y - (int)e.y_root).abs ();
            if (width < 1 || height < 1) {
                return true;
            }

            x = int.min (x, (int)e.x_root);
            y = int.min (y, (int)e.y_root);

            move (x, y);
            resize (width, height);

            return true;            
        }

        public override bool key_press_event (Gdk.EventKey e) {
            if (e.keyval == Gdk.Key.Escape) {
                cancelled ();
            }

            return true;            
        }

        public override void show_all () {
            base.show_all ();

            var manager = Gdk.Display.get_default ().get_default_seat ();
            var window = get_window ();

            var status = manager.grab (window,
                        Gdk.SeatCapabilities.ALL,
                        false,
                        new Gdk.Cursor.for_display (window.get_display (), Gdk.CursorType.CROSSHAIR),
                        new Gdk.Event (Gdk.EventType.BUTTON_PRESS | Gdk.EventType.BUTTON_RELEASE | Gdk.EventType.MOTION_NOTIFY),
                        null);

            if (status != Gdk.GrabStatus.SUCCESS) {
                manager.ungrab ();
            }
        }

        public new void close () {
            get_window ().set_cursor (null);
            base.close ();
        }

        public override bool draw (Cairo.Context ctx) {
            if (!dragging) {
                return true;
            }

            int w = get_allocated_width ();
            int h = get_allocated_height ();

            ctx.rectangle (0, 0, w, h);
            ctx.set_source_rgba (0.1, 0.1, 0.1, 0.2);
            ctx.fill ();

            ctx.rectangle (0, 0, w, h);
            ctx.set_source_rgb (0.7, 0.7, 0.7);
            ctx.set_line_width (1.0);
            ctx.stroke ();

            return base.draw (ctx);
        }
    }
}
