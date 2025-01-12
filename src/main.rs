use anyhow::Result;
use chrono::Utc;
use clap::Parser;
use colored::Colorize;
use indicatif::{MultiProgress, ProgressBar, ProgressStyle};
mod config;
mod error;
mod ssh;
use config::Args;
mod eval;
mod log;
use crate::eval::get_nix_config;
mod deploy;
use crate::deploy::deploy_host;

#[tokio::main]
async fn main() -> Result<()> {
    tracing_subscriber::fmt::init();

    let args = Args::parse();
    let config = get_nix_config(&args.flake_path, &args.quiet).await?;

    let requested_targets: Vec<&str> = match &args.targets {
        Some(targets) => targets.split(',').collect(),
        None => config.keys().map(std::string::String::as_str).collect(),
    };

    for target in &requested_targets {
        if !config.contains_key(*target) {
            anyhow::bail!("Target '{}' not found in deploy configuration", target);
        }
    }

    let multi_progress = MultiProgress::new();
    let futures: Vec<_> = requested_targets
        .iter()
        .map(|&target| {
            let host_config = &config[target];
            let pb = multi_progress.add(ProgressBar::new_spinner());
            pb.set_style(
                ProgressStyle::with_template("{spinner:.blue} {msg}")
                    .unwrap()
                    .tick_strings(&[
                        "●     ",
                        " ●    ",
                        "  ●   ",
                        "   ●  ",
                        "    ● ",
                        "     ●",
                        "    ● ",
                        "   ●  ",
                        "  ●   ",
                        " ●    ",
                        "●     ",
                        "●●●●●●",
                    ]),
                // The last string is used as the final tick string
            );
            pb.set_message(format!(
                "{} 🚀 Starting deployment...",
                format!("[{target}]").blue()
            ));
            deploy_host(
                target,
                host_config,
                &args.flake_path,
                pb,
                &args.quiet,
                &args.verbose,
            )
        })
        .collect();

    futures::future::join_all(futures)
        .await
        .into_iter()
        .collect::<Result<Vec<_>>>()?;

    multi_progress.clear().unwrap();
    println!(
        "{} {}",
        "✅ All deployments completed successfully".bold().green(),
        format!("at 🕒 {}", Utc::now().format("%Y-%m-%d %H:%M:%S")).bright_yellow()
    );
    Ok(())
}
