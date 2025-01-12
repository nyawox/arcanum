use clap::Parser;
use serde::Deserialize;

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct HostConfig {
    pub target: String,
    #[serde(default = "default_port")]
    pub port: u16,
    #[serde(default = "default_username")]
    pub username: String,
    #[serde(default = "default_connect_timeout")]
    pub connect_timeout: u16,
    #[serde(default)]
    pub retry: RetrySettings,
    #[serde(default = "default_control_persist")]
    pub control_persist: u16,
}

#[derive(Parser, Debug)]
#[command(author, version, about, long_about = None)]
pub struct Args {
    /// Optional targets to deploy to (comma-separated). If not specified, deploys to all targets
    #[arg(short, long)]
    pub targets: Option<String>,

    #[arg(long)]
    pub quiet: bool,

    #[arg(short, long)]
    pub verbose: bool,

    #[arg(short, long, default_value = ".")]
    pub flake_path: String,
}

fn default_connect_timeout() -> u16 {
    10
}
fn default_control_persist() -> u16 {
    60
}
fn default_port() -> u16 {
    22
}
fn default_username() -> String {
    "nixos".to_string()
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct RetrySettings {
    #[serde(default = "default_max_attempts")]
    pub max_attempts: u16,
    #[serde(default = "default_initial_delay")]
    pub initial_delay: u16,
    #[serde(default = "default_max_delay")]
    pub max_delay: u16,
}

fn default_max_attempts() -> u16 {
    5
}
fn default_initial_delay() -> u16 {
    5
}
fn default_max_delay() -> u16 {
    30
}

impl Default for RetrySettings {
    fn default() -> Self {
        Self {
            max_attempts: default_max_attempts(),
            initial_delay: default_initial_delay(),
            max_delay: default_max_delay(),
        }
    }
}
