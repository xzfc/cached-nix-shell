const SH_CMD : &str = include_str!("run.sh");

use std::os::unix::process::CommandExt;

pub fn run_drv(drv: &str, cmd: Vec<String>) {
    let mut args = vec!["-c", SH_CMD, "nope", "-p", ];
    args.extend(cmd.iter().map(|x|x.as_str()));

    let eee = std::process::Command::new("bash")
        .args(args)
        .exec();
}
