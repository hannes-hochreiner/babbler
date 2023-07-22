export def test [] {
  ^cargo test
}

export def build [] {
  test
  ^cargo build
}

export def intergration_test [] {
  with-env {
    BABBLER_FILENAME: "test_files/db.kdbx",
    BABBLER_PASSWORD: "test123"
  } {
    let output = (
    {
      "ls": "ls",
      "passwd": "show -sa password \"Test/test credential\"",
      "sec_value": "show -sa attr_sec \"Test2/another passwd\"",
      "username": "show -a username \"Test2/another passwd\"",
      "url": "show -a url \"Test2/another passwd\""
    }
    | to json | ^cargo run | from json)
    print $output
  }
}