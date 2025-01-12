{ tree-sitter, fetchFromGitHub }:

tree-sitter.buildGrammar {
  pname = "tree-sitter-kdl";
  version = "1.1.0-unstable-2024-06-08";
  language = "kdl";

  src = fetchFromGitHub {
    owner = "tree-sitter-grammars";
    repo = "tree-sitter-kdl";
    rev = "b37e3d58e5c5cf8d739b315d6114e02d42e66664";
    hash = "sha256-irx8aMEdZG2WcQVE2c7ahwLjqEoUAOOjvhDDk69a6lE=";
  };

}
