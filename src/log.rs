use anyhow::Result;
use bat::PrettyPrinter;
use colored::ColoredString;
use indicatif::ProgressBar;
use tokio::io::AsyncReadExt;

pub async fn print_stream<R: tokio::io::AsyncRead + Unpin>(
    mut stream: R,
    host_prefix: ColoredString,
    pb: ProgressBar,
    quiet: bool,
) -> Result<()> {
    let mut buf = [0u8; 1024];
    let mut current_line = String::new();

    loop {
        let n = stream.read(&mut buf).await?;
        if n == 0 {
            break;
        }

        if !quiet {
            let chunk = String::from_utf8_lossy(&buf[..n]);
            for c in chunk.chars() {
                if c == '\n' {
                    let highlighted_line = highlight_line(&current_line)?;
                    pb.println(format!("{host_prefix} {highlighted_line}"));
                    current_line.clear();
                } else {
                    current_line.push(c);
                }
            }
        }
    }

    // Flush remaining line
    if !current_line.is_empty() && !quiet {
        pb.println(format!("{host_prefix} {current_line}"));
    }

    Ok(())
}

fn highlight_line(line: &str) -> Result<String> {
    let mut output = String::new();
    PrettyPrinter::new()
        .input_from_bytes(line.as_bytes())
        .language("nix")
        .theme("base16") // until https://github.com/sharkdp/bat/pull/3099#issuecomment-2619925517, then i will hardcode catppuccin
        .print_with_writer(Some(&mut output))
        .map_err(|e| anyhow::anyhow!("Failed to highlight the syntax: {}", e))?;

    Ok(output.trim_end_matches('\n').to_string())
}

pub async fn capture_stdout_to_bytes(stream: tokio::process::ChildStdout) -> Result<Vec<u8>> {
    let mut output = Vec::new();
    let mut reader = tokio::io::BufReader::new(stream);
    reader.read_to_end(&mut output).await?;
    Ok(output)
}
