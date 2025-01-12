use anyhow::{Context, Result};
use chrono::Utc;
use colored::{ColoredString, Colorize};
use indicatif::ProgressBar;
use serde::Deserialize;
use std::{
    collections::HashMap,
    fs::remove_file,
    path::{Path, PathBuf},
};
use tokio::process::Command;

use crate::config::{HostConfig, RetrySettings};
use crate::error::retry_command;
use crate::log::{capture_stdout_to_bytes, print_stream};
use crate::ssh::{RemoteCommand, run_remote_command};

#[derive(Debug, Deserialize)]
struct NixEvalOutput {
    #[serde(rename = "drvPath")]
    drv_path: String,
    name: String,
    outputs: HashMap<String, String>,
    system: String,
}

async fn evaluate_configuration(
    host_name: &str,
    flake_path: &str,
    host_prefix: &ColoredString,
    host_prefix_pb: &ColoredString,
    pb: &ProgressBar,
    quiet: bool,
) -> Result<NixEvalOutput> {
    pb.set_message(format!(
        "{host_prefix_pb} 📝 Evaluating host configuration..."
    ));
    let flake_target =
        format!("{flake_path}#nixosConfigurations.{host_name}.config.system.build.toplevel");
    if !quiet {
        pb.println(format!(
            "{host_prefix} {} {} {flake_target}",
            "🎯".bright_blue(),
            "Target:".to_string().bright_blue(),
        ));
    }
    let mut eval_child = Command::new("nix-eval-jobs")
        .args([
            "--gc-roots-dir",
            "gcroot",
            "--log-format",
            "multiline-with-logs",
            "--flake",
            &flake_target,
        ])
        .stdout(std::process::Stdio::piped())
        .stderr(std::process::Stdio::piped())
        .spawn()
        .context("Failed to spawn nix-eval-jobs")?;

    let stdout = eval_child.stdout.take().unwrap();
    let stderr = eval_child.stderr.take().unwrap();

    let stderr_task = tokio::spawn(print_stream(stderr, host_prefix.clone(), pb.clone(), quiet));

    let stdout_output = capture_stdout_to_bytes(stdout);

    let (stdout_result, _stderr_result) = tokio::join!(stdout_output, stderr_task);
    let stdout_bytes = stdout_result.context("Failed to read stdout")?;

    let status = eval_child.wait().await?;
    if !status.success() {
        anyhow::bail!("nix-eval-jobs failed with status {}", status);
    }
    pb.set_message(format!("{host_prefix_pb} ✅ Evaluated configuration"));

    serde_json::from_slice(&stdout_bytes).context("Failed to parse nix-eval-jobs output")
}

async fn build_configuration(
    drv_path: &str,
    tmp_path: &Path,
    host_prefix: &str,
    host_prefix_pb: &ColoredString,
    pb: &ProgressBar,
    quiet: bool,
) -> Result<()> {
    pb.set_message(format!("{host_prefix_pb} 🔨 Building configuration..."));
    let mut cmd = Command::new("nix");
    cmd.args([
        "build",
        "--log-format",
        "multiline-with-logs",
        "-o",
        tmp_path.to_str().unwrap(),
        &format!("{drv_path}^*"),
    ])
    .stdout(std::process::Stdio::piped())
    .stderr(std::process::Stdio::piped());

    let mut child = cmd.spawn().context("Failed to spawn nix build")?;

    let stdout = child.stdout.take().unwrap();
    let stderr = child.stderr.take().unwrap();

    tokio::spawn(print_stream(
        stdout,
        host_prefix.normal(),
        pb.clone(),
        quiet,
    ));

    tokio::spawn(print_stream(
        stderr,
        host_prefix.normal(),
        pb.clone(),
        quiet,
    ));

    let status = child.wait().await?;

    if status.success() {
        pb.set_message(format!("{host_prefix_pb} ✅ Built configuration"));
        Ok(())
    } else {
        Err(anyhow::anyhow!("Build failed with exit status {}", status))
    }
}

async fn copy_closure(
    output_path: &str,
    host_config: &HostConfig,
    host_prefix: &ColoredString,
    host_prefix_pb: &ColoredString,
    pb: &ProgressBar,
    quiet: bool,
) -> Result<()> {
    pb.set_message(format!("{host_prefix_pb} 📤 Copying closure to target...",));
    let mut cmd = Command::new("nix-copy-closure");
    cmd.args([
        "-s",
        "--gzip",
        "-v",
        "--log-format",
        "multiline-with-logs",
        "--to",
        &format!("{}@{}", host_config.username, host_config.target),
        output_path,
    ])
    .stdout(std::process::Stdio::piped())
    .stderr(std::process::Stdio::piped());

    let ssh_options = host_config.build_ssh_options();
    let ssh_opts_str = ssh_options.join(" ");
    cmd.env("NIX_SSHOPTS", ssh_opts_str);

    let mut child = cmd.spawn().context("Failed to spawn nix-copy-closure")?;

    let stdout = child.stdout.take().unwrap();
    let stderr = child.stderr.take().unwrap();

    tokio::spawn(print_stream(stdout, host_prefix.clone(), pb.clone(), quiet));

    tokio::spawn(print_stream(stderr, host_prefix.clone(), pb.clone(), quiet));

    let status = child.wait().await?;

    if status.success() {
        pb.set_message(format!("{host_prefix_pb} ✅ Copied closure"));
        Ok(())
    } else {
        Err(anyhow::anyhow!("Copy failed with exit status {}", status))
    }
}

#[allow(clippy::too_many_lines)]
pub async fn deploy_host(
    host_name: &str,
    host_config: &HostConfig,
    flake_path: &str,
    pb: ProgressBar,
    quiet: &bool,
    verbose: &bool,
) -> Result<()> {
    let retry_config = RetrySettings::default();
    let host_prefix = format!("[{host_name}]").magenta();
    let host_prefix_pb = format!("[🖥️ {host_name}]").blue();

    pb.enable_steady_tick(std::time::Duration::from_millis(150));
    if !quiet {
        pb.println(format!(
            "\n{} {} {}",
            host_prefix,
            "🚀 Starting deployment".green().bold(),
            format!("at 🕒 {}", Utc::now().format("%Y-%m-%d %H:%M:%S"))
                .bright_yellow()
                .bold()
        ));
    }

    let eval_output = evaluate_configuration(
        host_name,
        flake_path,
        &host_prefix,
        &host_prefix_pb,
        &pb,
        *quiet,
    )
    .await?;
    if !quiet {
        pb.println(format!(
            "{host_prefix} {} {} {} ({})",
            "📦".bright_blue(),
            "System:".bright_blue(),
            eval_output.name,
            eval_output.system
        ));
        pb.println(format!(
            "{host_prefix} {} {} {}",
            "📦".bright_blue(),
            "Derivation:".to_string().bright_blue(),
            eval_output.drv_path
        ));
    }
    let output_path = eval_output
        .outputs
        .get("out")
        .context("No 'out' path in outputs")?;
    if !quiet {
        pb.println(format!(
            "{host_prefix} {} {} {output_path}",
            "📍".bright_blue(),
            "Output path:".to_string().bright_blue(),
        ));
    }
    let tmp_path = PathBuf::from("/tmp").join(format!("nix-rebuild-{host_name}"));
    retry_command(
        host_name,
        "Build",
        &retry_config,
        || {
            build_configuration(
                &eval_output.drv_path,
                &tmp_path,
                &host_prefix,
                &host_prefix_pb,
                &pb,
                *quiet,
            )
        },
        &pb,
        verbose,
        quiet,
    )
    .await?;

    retry_command(
        host_name,
        "Closure copy",
        &retry_config,
        || {
            copy_closure(
                output_path,
                host_config,
                &host_prefix,
                &host_prefix_pb,
                &pb,
                *quiet,
            )
        },
        &pb,
        verbose,
        quiet,
    )
    .await?;

    let ssh_cmd = host_config.build_ssh_command();
    remove_file(&tmp_path).context("Failed to remove temporary symlink")?;

    pb.set_message(format!("{host_prefix_pb} 🔄 Activating configuration..."));
    let combined_command = format!(
        "sudo sh -c '\
        {output_path}/bin/switch-to-configuration test && \
        nix-env -p /nix/var/nix/profiles/system --set {output_path} && \
        {output_path}/bin/switch-to-configuration boot && \
        {output_path}/bin/switch-to-configuration switch\
        '"
    );

    run_remote_command(RemoteCommand {
        host_name,
        ssh_cmd: &ssh_cmd,
        command: &combined_command,
        host_config,
        mode: "Configuration switch",
        pb: &pb,
        quiet,
        verbose,
    })
    .await?;

    pb.set_message(format!(
        "{} Successfully deployed at 🕒 {}",
        host_prefix_pb,
        Utc::now().format("%Y-%m-%d %H:%M:%S")
    ));
    pb.finish();
    Ok(())
}
