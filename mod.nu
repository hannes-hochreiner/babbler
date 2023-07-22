export def test [] {
  ^cargo test
}

export def build [] {
  test
  ^cargo build
}

export def intergration_test [] {
  let output = ({
    filename: "test_files/db.kdbx",
    password: "test123",
    commands: [
      {key: "ls", value: "ls"}, 
      {key: "passwd", value: "show -sa password \"Test/test credential\""}
      {key: "sec_value", value: "show -sa attr_sec \"Test2/another passwd\""}
      {key: "username", value: "show -a username \"Test2/another passwd\""}
      {key: "url", value: "show -a url \"Test2/another passwd\""}
    ]
  } | to json | ^cargo run | from json)
  print $output
}