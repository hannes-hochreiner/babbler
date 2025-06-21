export def test [] {
  ^cargo test
}

export def build [] {
  test
  ^cargo build
}

export def nix-build [] {
  ^nix build
}

export def update [] {
	let deps_info = (get-deps-info)

  ^cargo update
  {
    "deps": ($deps_info.hash),
		"cargo_config": ($deps_info.cargo_config)
    "cargo_lock": (open Cargo.lock | hash sha256)
  } | to toml | save -f hashes.toml
  ^nix flake update
}

def get-deps-info [] {
  let temp_path = $"/tmp/babbler_deps_(random uuid)"

  mkdir $temp_path
	let deps_info = {
		cargo_config: (cargo vendor $temp_path)
		hash: (nix hash path $temp_path)
	}

  rm -r $temp_path

  $deps_info
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