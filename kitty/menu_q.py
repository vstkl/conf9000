# kitty kitten bound to `q` in the waybar network menu (waybar/scripts/network.sh).
# nmtui has no quit key, so `q` closes the window -- but only on screens without a text
# field, otherwise it types a literal q (wifi passwords, connection names, hostname).
from kittens.tui.handler import result_handler

# screens where `q` closes the menu (text that is only visible on them)
CLOSE_ON = ("Please select an option", "<Activate>", "<Deactivate>", "<Back>", "<Quit>", "Radio")
# a text field is visible -> `q` is typed
TYPE_ON = ("Password", "Profile name", "Hostname", "Authentication required")


def main(args):
    pass


@result_handler(no_ui=True)
def handle_result(args, answer, target_window_id, boss):
    w = boss.window_id_map.get(target_window_id)
    if w is None:
        return
    screen = w.as_text()
    if any(s in screen for s in CLOSE_ON) and not any(s in screen for s in TYPE_ON):
        boss.mark_window_for_close(w)
    else:
        w.write_to_child(b"q")
