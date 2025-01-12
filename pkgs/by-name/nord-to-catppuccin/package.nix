{ lib, stdenv }:

stdenv.mkDerivation {
  name = "nord-to-catppuccin";
  version = "0.1.0";
  dontUnpack = true;

  buildPhase = ''
    mkdir -p $out/bin
    cat > $out/bin/nord-to-catppuccin << 'EOL'
    #!${stdenv.shell}

    find . \( \
      -name "*.ts" -o \
      -name "*.tsx" -o \
      -name "*.js" -o \
      -name "*.jsx" -o \
      -name "*.css" -o \
      -name "*.scss" -o \
      -name "*.sass" -o \
      -name "*.html" -o \
      -name "*.mdx" -o \
      -name "*.svg" -o \
      -name "*.json" \
    \) -exec sed -i \
      -e 's/2e3440/11111b/Ig' \
      -e 's/3b4252/181825/Ig' \
      -e 's/434c5e/1e1e2e/Ig' \
      -e 's/4c566a/313244/Ig' \
      -e 's/d8dee9/cdd6f4/Ig' \
      -e 's/e5e9f0/bac2de/Ig' \
      -e 's/eceff4/a6adc8/Ig' \
      -e 's/8fbcbb/94e2d5/Ig' \
      -e 's/88c0d0/89dceb/Ig' \
      -e 's/81a1c1/74c7ec/Ig' \
      -e 's/5e81ac/89b4fa/Ig' \
      -e 's/bf616a/f38ba8/Ig' \
      -e 's/d08770/fab387/Ig' \
      -e 's/ebcb8b/f9e2af/Ig' \
      -e 's/a3be8c/a6e3a1/Ig' \
      -e 's/b48ead/cba6f7/Ig' \
      -e 's/46 52 64/17 17 27/Ig' \
      -e 's/59 66 82/24 24 37/Ig' \
      -e 's/67 76 94/30 30 46/Ig' \
      -e 's/76 86 106/49 50 68/Ig' \
      -e 's/216 222 233/205 214 244/Ig' \
      -e 's/229 233 240/186 194 222/Ig' \
      -e 's/236 239 244/166 173 200/Ig' \
      -e 's/143 188 187/148 226 213/Ig' \
      -e 's/136 192 208/137 220 235/Ig' \
      -e 's/129 161 193/116 199 236/Ig' \
      -e 's/94 129 172/137 180 250/Ig' \
      -e 's/191 97 106/243 139 168/Ig' \
      -e 's/208 135 112/250 179 135/Ig' \
      -e 's/235 203 139/249 226 175/Ig' \
      -e 's/163 190 140/166 227 161/Ig' \
      -e 's/180 142 173/203 166 247/Ig' \
      -e 's/46, 52, 64/17, 17, 27/Ig' \
      -e 's/59, 66, 82/24, 24, 37/Ig' \
      -e 's/67, 76, 94/30, 30, 46/Ig' \
      -e 's/76, 86, 106/49, 50, 68/Ig' \
      -e 's/216, 222, 233/205, 214, 244/Ig' \
      -e 's/229, 233, 240/186, 194, 222/Ig' \
      -e 's/236, 239, 244/166, 173, 200/Ig' \
      -e 's/143, 188, 187/148, 226, 213/Ig' \
      -e 's/136, 192, 208/137, 220, 235/Ig' \
      -e 's/129, 161, 193/116, 199, 236/Ig' \
      -e 's/94, 129, 172/137, 180, 250/Ig' \
      -e 's/191, 97, 106/243, 139, 168/Ig' \
      -e 's/208, 135, 112/250, 179, 135/Ig' \
      -e 's/235, 203, 139/249, 226, 175/Ig' \
      -e 's/163, 190, 140/166, 227, 161/Ig' \
      -e 's/180, 142, 173/203, 166, 247/Ig' \
      {} \;

    EOL

    chmod +x $out/bin/nord-to-catppuccin
  '';

  meta = with lib; {
    description = "Replace Nord with Catppuccin Mocha";
    license = licenses.mit;
    maintainers = with maintainers; [ nyawox ];
    platforms = platforms.all;
    mainProgram = "nord-to-catppuccin";
  };
}
