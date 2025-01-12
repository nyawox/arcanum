{
  firejail,
  fetchFromGitHub,
}:
firejail.overrideAttrs (_old: {
  pname = "firejail-unstable";
  version = "landlock-split-unstable-2025-01-21";
  src = fetchFromGitHub {
    owner = "netblue30";
    repo = "firejail";
    rev = "bd946e3594f27190b4a948444c0c1622d29a60f2";
    hash = "sha256-9ZQYyXQ2IV5ZTxlnVSi2o7X/iKAclRYK2a+Q3f1qagA=";
  };
})
