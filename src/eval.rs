use crate::log::capture_stdout_to_bytes;
use anyhow::{Context, Result};
use colored::Colorize;
use indicatif::ProgressBar;
use std::collections::HashMap;
use tokio::process::Command;

use crate::config::HostConfig;
use crate::log::print_stream;

pub async fn get_nix_config(flake_path: &str, quiet: &bool) -> Result<HashMap<String, HostConfig>> {
    let mut cmd = Command::new("nix");
    cmd.args([
        "eval",
        "--log-format",
        "multiline-with-logs",
        "--print-build-logs",
        "--verbose",
        "--json",
        &format!("{flake_path}#deployment"),
    ])
    .stdout(std::process::Stdio::piped())
    .stderr(std::process::Stdio::piped());

    let mut child = cmd.spawn().context("Failed to spawn nix eval")?;
    let stdout = child.stdout.take().unwrap();
    let stderr = child.stderr.take().unwrap();

    // without host prefix (global command)
    let stderr_task = tokio::spawn(print_stream(
        stderr,
        String::new().normal(), // No host prefix
        ProgressBar::hidden(),  // Dummy pb
        *quiet,
    ));

    let stdout_output = capture_stdout_to_bytes(stdout);

    let (stdout_result, _stderr_result) = tokio::join!(stdout_output, stderr_task);
    let stdout_bytes = stdout_result.context("Failed to read stdout")?;

    let status = child.wait().await?;
    if !status.success() {
        anyhow::bail!("nix eval failed with status {}", status);
    }

    let config: HashMap<String, HostConfig> =
        serde_json::from_slice(&stdout_bytes).context("Failed to parse nix evaluation output")?;

    Ok(config)
}
