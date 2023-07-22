# babbler
A utility to obtain information from KeepassXC using `keepassxc-cli`.

## Usage

The utility expects two environment variables to be set to obtain the Keepass database filename and password.

variable name | description
---|---
BABBLER_FILENAME | name of the Keepass database file
BABBLER_PASSWORD | password for the Keepass database file

The commands to be run can be supplied on `stdin` in a JSON dictionary containing identifiers as keys and the commands as values.
The output is provided on `stdout` in a similar JSON dictionary where the same identifiers are used as keys and the values are the responses from KeepassXC.

An example, which works with the file `db.kdbx` in the folder `test_files`, can be found below:

```JSON
{
  "ls": "ls",
  "passwd": "show -sa password \"Test/test credential\"",
  "sec_value": "show -sa attr_sec \"Test2/another passwd\"",
  "username": "show -a username \"Test2/another passwd\"",
  "url": "show -a url \"Test2/another passwd\""
}
```

The corresponding output is:

```JSON
{
  "ls": "Test/\nTest2/",
  "passwd": "27C9vkiE9ZO6oBoD37Cx",
  "sec_value": "sec_value",
  "username": "username",
  "url": "https://another.domain"
}
```

A usage example is shown in the `integration_test` function of the `mod.nu` file:

```nu
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
```

**Note:** for production use, please avoid hardcoding the password.

## License

This work is licensed under the MIT or Apache 2.0 license.

`SPDX-License-Identifier: MIT OR Apache-2.0`