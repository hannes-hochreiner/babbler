use anyhow::{ensure, Result};
use serde::{Deserialize, Serialize};
use std::process::Stdio;
use tokio::{
    io::{self, AsyncReadExt, AsyncWriteExt},
    process::Command,
};

#[derive(Serialize, Deserialize)]
struct Input {
    filename: String,
    password: String,
    commands: Vec<KeyValue>,
}

#[derive(Debug, PartialEq, Serialize, Deserialize)]
struct KeyValue {
    key: String,
    value: String,
}

#[tokio::main]
async fn main() -> Result<()> {
    let mut input_string = String::new();

    io::stdin().read_to_string(&mut input_string).await?;

    let input = serde_json::from_str::<Input>(&input_string)?;

    let mut cmd = Command::new("keepassxc-cli");

    cmd.stdout(Stdio::piped());
    cmd.stdin(Stdio::piped());
    cmd.args(&["open", "-q", &input.filename]);

    let mut child = cmd.spawn().expect("failed to spawn command");
    let mut stdin = child
        .stdin
        .take()
        .expect("child did not have a handle to stdin");
    let mut stdout = child
        .stdout
        .take()
        .expect("child did not have a handle to stdout");

    stdin
        .write_all(format!("{}\n", input.password).as_bytes())
        .await
        .expect("could not write to stdin");

    let mut stdout_string = read(&mut stdout).await?;
    let prompt = stdout_string.clone();

    stdin
        .write_all(
            format!(
                "{}\nquit\n",
                input
                    .commands
                    .iter()
                    .map(|elem| elem.value.as_str())
                    .collect::<Vec<&str>>()
                    .join("\n")
            )
            .as_bytes(),
        )
        .await
        .expect("could not write to stdin");
    stdout.read_to_string(&mut stdout_string).await.unwrap();

    let output = parse_output(&prompt, &input.commands, &stdout_string)?;

    io::stdout()
        .write_all(serde_json::to_string(&output)?.as_bytes())
        .await?;

    Ok(())
}

async fn read<T: AsyncReadExt + std::marker::Unpin>(stdfd: &mut T) -> Result<String> {
    let mut buffer = [0; 256];
    let len = stdfd.read(&mut buffer).await?;
    Ok(String::from_utf8(buffer[..len].to_vec())?)
}

fn parse_output(prompt: &str, input: &Vec<KeyValue>, stdout_string: &str) -> Result<Vec<KeyValue>> {
    let mut output = Vec::new();
    let mut stdout_lines = stdout_string.lines();
    let mut current_line = stdout_lines.next();

    for kv in input {
        ensure!(
            format!("{}{}", prompt, kv.value)
                == current_line.ok_or(anyhow::anyhow!("expected line"))?,
            "\"{}\" == \"{}\"",
            format!("{}{}", prompt, kv.value),
            current_line.ok_or(anyhow::anyhow!("expected line"))?
        );
        let mut collector = Vec::<String>::new();

        current_line = stdout_lines.next();

        while let Some(ln) = current_line {
            if ln.starts_with(prompt) {
                break;
            }

            collector.push(ln.to_string());
            current_line = stdout_lines.next();
        }

        ensure!(collector.len() > 0);

        output.push(KeyValue {
            key: kv.key.clone(),
            value: collector.join("\n"),
        });
    }

    Ok(output)
}

#[cfg(test)]
mod tests {
    use crate::*;

    #[test]
    fn parse_output_1() {
        let input = Input {
            filename: "testfile".to_string(),
            password: "test123".to_string(),
            commands: vec![
                KeyValue {
                    key: "ls".to_string(),
                    value: "ls".to_string(),
                },
                KeyValue {
                    key: "test".to_string(),
                    value: "show -sa password \"Test/test credential\"".to_string(),
                },
            ],
        };
        let stdout = "TestDB> ls\nTest/\nTestDB> show -sa password \"Test/test credential\"\n27C9vkiE9ZO6oBoD37Cx\nTestDB> quit\n";
        let prompt = "TestDB> ";

        assert_eq!(
            parse_output(prompt, &input.commands, stdout).unwrap(),
            vec![
                KeyValue {
                    key: "ls".to_string(),
                    value: "Test/".to_string()
                },
                KeyValue {
                    key: "test".to_string(),
                    value: "27C9vkiE9ZO6oBoD37Cx".to_string()
                }
            ]
        );
    }
}
