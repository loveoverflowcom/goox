use goox_core::api::{
    create_terminal, dispose_terminal, poll_terminal_screen, send_terminal_input,
};
use std::thread;
use std::time::Duration;

fn main() {
    let terminal_id = match create_terminal(24, 80, None) {
        Ok(id) => id,
        Err(error) => {
            eprintln!("failed to create terminal: {error}");
            std::process::exit(1);
        }
    };

    let _ = send_terminal_input(terminal_id, b"printf 'goox terminal demo\\n'\n".to_vec());
    thread::sleep(Duration::from_millis(400));

    match poll_terminal_screen(terminal_id) {
        Ok(snapshot) => {
            println!(
                "terminal={} gen={} exited={} exit={:?}",
                snapshot.terminal_id, snapshot.generation, snapshot.exited, snapshot.exit_message
            );
            for row in snapshot.grid {
                let line: String = row
                    .cells
                    .into_iter()
                    .map(|cell| {
                        if cell.ch == " " {
                            ' '
                        } else {
                            cell.ch.chars().next().unwrap_or(' ')
                        }
                    })
                    .collect();
                println!("{line}");
            }
        }
        Err(error) => {
            eprintln!("failed to poll terminal: {error}");
        }
    }

    dispose_terminal(terminal_id);
}
