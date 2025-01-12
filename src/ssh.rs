use anyhow::{Context, Result};
use colored::Colorize;
use indicatif::ProgressBar;
use tokio::process::Command;

use crate::config::HostConfig;
use crate::error::retry_command;
use crate::log::print_stream;

impl HostConfig {
    pub fn build_ssh_options(&self) -> Vec<String> {
        let mut options = Vec::new();

        let ssh_opts = vec![
            format!("ConnectTimeout={}", self.connect_timeout),
            format!("ControlPath=~/.ssh/deploy-%r@%h:%p"),
            format!("ControlPersist={}", self.control_persist),
            "ControlMaster=auto".to_string(),
            "LogLevel=FATAL".to_string(),
            "VisualHostKey=no".to_string(),
        ];

        for opt in ssh_opts {
            options.push("-o".to_string());
            options.push(opt);
        }

        options.push("-p".to_string());
        options.push(self.port.to_string());

        options
    }

    pub fn build_ssh_command(&self) -> Vec<String> {
        let mut cmd = vec!["ssh".to_string()];
        cmd.extend(self.build_ssh_options());
        cmd.push(format!("{}@{}", self.username, self.target));
        cmd
    }
}

pub struct RemoteCommand<'a> {
    pub host_name: &'a str,
    pub ssh_cmd: &'a [String],
    pub command: &'a str,
    pub host_config: &'a HostConfig,
    pub mode: &'a str,
    pub pb: &'a ProgressBar,
    pub quiet: &'a bool,
    pub verbose: &'a bool,
}

pub async fn run_remote_command(config: RemoteCommand<'_>) -> Result<()> {
    let func = || async {
        let host_prefix = format!("[{}]", config.host_name).magenta();
        let mut child = Command::new(&config.ssh_cmd[0])
            .args(&config.ssh_cmd[1..])
            .arg("--")
            .arg(config.command)
            .stdout(std::process::Stdio::piped())
            .stderr(std::process::Stdio::piped())
            .spawn()
            .context(format!("Failed to execute {}", config.mode))?;

        let stdout = child.stdout.take().unwrap();
        let stderr = child.stderr.take().unwrap();

        tokio::spawn(print_stream(
            stdout,
            host_prefix.clone(),
            config.pb.clone(),
            *config.quiet,
        ));

        tokio::spawn(print_stream(
            stderr,
            host_prefix.clone(),
            config.pb.clone(),
            *config.quiet,
        ));

        let status = child.wait().await?;

        if !status.success() {
            anyhow::bail!("{} failed with status {}", config.mode, status);
        }
        Ok(())
    };

    retry_command(
        config.host_name,
        config.mode,
        &config.host_config.retry,
        func,
        config.pb,
        config.verbose,
        config.quiet,
    )
    .await
}
