use anyhow::Result;
use colored::Colorize;
use indicatif::ProgressBar;
use std::error::Error;
use tokio::time::Duration;

use crate::config::RetrySettings;

#[derive(Debug)]
pub enum DeploymentErrorKind {
    Retryable,
    NonRetryable,
}

pub fn classify_error(
    err: &(dyn Error + 'static),
    host_prefix: &str,
    pb: &ProgressBar,
    verbose: bool,
) -> DeploymentErrorKind {
    let error_str = err.to_string().to_lowercase();
    if verbose {
        pb.println(format!(
            "{host_prefix} DEBUG: Classifying error: {error_str}",
        ));
    }

    let retryable_patterns = [
        "nix-copy-closure failed with status exit status: 1",
        "copy failed",
        "configuration switch failed with status exit status: 255",
    ];

    if retryable_patterns
        .iter()
        .any(|&pattern| error_str.contains(pattern))
    {
        if verbose {
            pb.println(format!(
                "{host_prefix} DEBUG: Classified as Retryable error",
            ));
        }
        DeploymentErrorKind::Retryable
    } else {
        if verbose {
            pb.println(format!(
                "{host_prefix} DEBUG: Classified as NonRetryable error",
            ));
        }
        DeploymentErrorKind::NonRetryable
    }
}

pub async fn retry_command<F, Fut, T>(
    host_name: &str,
    mode: &str,
    retry_settings: &RetrySettings,
    f: F,
    pb: &ProgressBar,
    verbose: &bool,
    quiet: &bool,
) -> Result<T>
where
    F: Fn() -> Fut,
    Fut: std::future::Future<Output = Result<T>>,
{
    let host_prefix = format!("[{host_name}]").magenta();
    let host_prefix_pb = format!("[🖥️ {host_name}]").blue();
    let mut attempt = 1;
    let mut delay = Duration::from_secs(u64::from(retry_settings.initial_delay));
    let max_delay = Duration::from_secs(u64::from(retry_settings.max_delay));
    let max_attempts = retry_settings.max_attempts;

    loop {
        match f().await {
            Ok(result) => return Ok(result),
            Err(e) => {
                if !quiet {
                    pb.println(format!(
                        "{} {} {}: {:#}",
                        host_prefix,
                        "🔍".dimmed(),
                        "Full error".red(),
                        e
                    ));
                }

                match classify_error(&*e, &host_prefix, pb, *verbose) {
                    DeploymentErrorKind::Retryable if attempt < max_attempts => {
                        pb.set_message(format!(
                            "{} {} {} failed (attempt {}/{}). Retrying in {} seconds...",
                            host_prefix_pb,
                            "🔄".yellow(),
                            mode,
                            attempt,
                            max_attempts,
                            delay.as_secs().to_string().yellow()
                        ));
                        tokio::time::sleep(delay).await;
                        delay = std::cmp::min(delay * 2, max_delay);
                        attempt += 1;
                    }
                    _ => {
                        pb.set_message(format!(
                            "{} {} Error not retryable or attempts exhausted",
                            host_prefix_pb,
                            "❌".red()
                        ));
                        return Err(e);
                    }
                }
            }
        }
    }
}
