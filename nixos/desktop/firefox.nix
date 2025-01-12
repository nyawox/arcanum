{
  inputs,
  pkgs,
  lib,
  config,
  arcanum,
  ...
}:
let
  exturl = "https://addons.mozilla.org/firefox/downloads/latest";
in
{
  userPersist.directories = lib.singleton ".mozilla";
  homeImports = lib.singleton inputs.schizofox.homeManagerModule;
  homeConfig = {
    programs.schizofox = {
      enable = true;
      # Search engine policies requires ESR
      search = {
        defaultSearchEngine = "sx";
        removeEngines = [
          "Brave"
          "Bing"
          "Amazon.com"
          "eBay"
          "Twitter"
          "Wikipedia (en)"
          "Google"
          "DuckDuckGo"
        ];
        addEngines = [
          {
            Name = "sx";
            Description = "selfhosted searxng";
            Alias = "sx";
            Method = "GET";
            URLTemplate = "https://search.${arcanum.domain}/search?q={searchTerms}";
          }
          {
            Name = "pp";
            Description = "Perplexity";
            Alias = "pp";
            Method = "GET";
            URLTemplate = "https://www.perplexity.ai/search?q={searchTerms}";
          }
        ];
      };

      security = {
        sanitizeOnShutdown.enable = false;
        sandbox = {
          enable = true;
          allowFontPaths = true;
          extraBinds = [
            "/home/${arcanum.username}/.config/tridactyl"
            # xdg-open
            "/etc/profiles/per-user/${arcanum.username}/share/applications"
            "/run/current-system/sw/share/applications"
            "/home/${arcanum.username}/.cache/com.bitwarden.desktop" # desktop_proxy needs access here
          ];
        };
      };

      misc = {
        drm.enable = true;
        disableWebgl = false;
        firefoxSync = true;
        translate.enable = true;
        startPageURL = "https://admin-apps.${arcanum.domain}";
      };

      extensions = {
        enableDefaultExtensions = true;
        enableExtraExtensions = true;
        simplefox.enable = false;
        darkreader.enable = true;

        extraExtensions = {
          "webextension@metamask.io".install_url = "${exturl}/ether-metamask/latest.xpi";
          "languagetool-webextension@languagetool.org".install_url = "${exturl}/languagetool/latest.xpi";
          "{9a41dee2-b924-4161-a971-7fb35c053a4a}".install_url = "${exturl}/enhanced-h264ify/latest.xpi";
          "{446900e4-71c2-419f-a6a7-df9c091e268b}".install_url =
            "${exturl}/bitwarden-password-manager/latest.xpi";
          "{a4c4eda4-fb84-4a84-b4a1-f7c1cbf2a1ad}".install_url = "${exturl}/refined-github-/latest.xpi";
          "sponsorBlocker@ajay.app".install_url = "${exturl}/sponsorblock/latest.xpi";
          "{f209234a-76f0-4735-9920-eb62507a54cd}".install_url = "${exturl}/unpaywall/latest.xpi";
          "gdpr@cavi.au.dk".install_url = "${exturl}/consent-o-matic/latest.xpi";
          "{762f9885-5a13-4abd-9c77-433dcd38b8fd}".install_url =
            "${exturl}/return-youtube-dislikes/latest.xpi";
          "@contain-amzn".install_url = "${exturl}/contain-amazon/latest.xpi";
          "{a6c4a591-f1b2-4f03-b3ff-767e5bedf4e7}".install_url =
            "${exturl}/user-agent-string-switcher/latest.xpi";
          "firefox-addon@pronoundb.org".install_url = "${exturl}/pronoundb/latest.xpi";
          "{a218c3db-51ef-4170-804b-eb053fc9a2cd}".install_url = "${exturl}/qr-code-address-bar/latest.xpi";
          "{93f81583-1fd4-45cc-bff4-abba952167bb}".install_url = "${exturl}/jiffy-reader/latest.xpi";
          "tridactyl.vim@cmcaine.co.uk".install_url = "${exturl}/tridactyl-vim/latest.xpi";
          "shinigamieyes@shinigamieyes".install_url = "${exturl}/shinigami-eyes/latest.xpi";
          "7esoorv3@alefvanoon.anonaddy.me".install_url = "${exturl}/libredirect/latest.xpi";
          "{5f2806a5-f66d-40c6-8fb2-6018753b5626}".install_url = "${exturl}/icloud-hide-my-email/latest.xpi";
          "clipper@obsidian.md".install_url = "${exturl}/web-clipper-obsidian/latest.xpi";
        };
      };

      settings = {
        #Disable autofocus on input fields
        "browser.autofocus" = false;
        #use my own fonts
        "browser.display.use_document_fonts" = true;
        # Fill SVG Color
        "svg.context-properties.content.enabled" = true;

        # CSS's `:has()` selector
        "layout.css.has-selector.enabled" = true;

        # Integrated calculator at urlbar
        "browser.urlbar.suggest.calculator" = true;

        # Integrated unit convertor at urlbar
        "browser.urlbar.unitConversion.enabled" = true;

        # Trim  URL
        "browser.urlbar.trimHttps" = true;
        "browser.urlbar.trimURLs" = true;

        # GTK rounded corners
        "widget.gtk.rounded-bottom-corners.enabled" = true;
        # configure fonts
        "font.name-list.emoji" = "Apple Color Emoji";
        "font.name.monospace.x-western" = "SF Mono"; # bitmap font don't look good in websites
        "font.name.sans-serif.x-western" = config.stylix.fonts.sansSerif.name;
        "font.name.serif.x-western" = config.stylix.fonts.serif.name;
        "font.size.monospace.x-western" = 16;
        "font.size.variable.x-western" = 16;
        #####
        #Smoother scroll
        "general.smoothScroll.msdPhysics.enabled" = true;
        "general.smoothScroll.msdPhysics.continuousMotionMaxDeltaMS" = 250;
        "general.smoothScroll.msdPhysics.motionBeginSpringConstant" = 450;
        "general.smoothScroll.msdPhysics.regularSpringConstant" = 450;
        "general.smoothScroll.msdPhysics.slowdownMinDeltaMS" = 50;
        "general.smoothScroll.msdPhysics.slowdownMinDeltaRatio" = 0.4;
        "general.smoothScroll.msdPhysics.slowdownSpringConstant" = 5000;
        "general.smoothScroll.currentVelocityWeighting" = 0;
        "general.smoothScroll.mouseWheel.durationMaxMS" = 250;
        "general.smoothScroll.stopDecelerationWeighting" = 0.82;
        "mousewheel.min_line_scroll_amount" = 30;
        "toolkit.scrollbox.verticalScrollDistance" = 5;
        "toolkit.scrollbox.horizontalScrollDistance" = 4;
        # Downloading random files from http website is super annoying with this.
        "dom.block_download_insecure" = false;

        # Always use XDG portals for stuff
        "widget.use-xdg-desktop-portal.file-picker" = 1;

        # css
        "ultima.tabs.vertical" = true;
        "ultima.tabs.size.l" = true;
        "ultima.tabs.autohide" = true;
        "ultima.tabs.closetabsbutton" = true;
        "ultima.sidebar.autohide" = true;
        "ultima.sidebar.longer" = true;
        "ultima.theme.extensions" = true;
        "ultima.urlbar.suggestions" = true;
        "ultima.urlbar.centered" = true;
        "ultima.xstyle.containertabs.111" = true;
        "ultima.xstyle.pinnedtabs.1" = true;
        "ultima.OS.mac" = true;
        "browser.uidensity" = 0;
        "browser.aboutConfig.showWarning" = false;
        "browser.tabs.hoverPreview.enabled" = true;
        "user.theme.dark.catppuccin-mocha" = true;

        # prevent popups from automatically closing
        # "ui.popup.disable_autohide" = true;
      };
      theme = {
        font = config.stylix.fonts.serif.name;

        defaultUserChrome.enable = false;
        defaultUserContent.enable = false;

        extraUserChrome =
          # css
          ''

            @import url(theme/all-global-positioning.css);

            @import url(theme/all-color-schemes.css);

            @import url(theme/position-tabs.css);
            @import url(theme/position-findbar.css);
            @import url(theme/position-window-controls.css);

            @import url(theme/function-mini-button-bar.css);
            @import url(theme/function-sidebar-autohide.css);
            @import url(theme/function-containers-indicator.css);
            @import url(theme/function-menu-button.css);
            @import url(theme/function-privatemode-indicator.css);
            @import url(theme/function-urlbar.css);
            @import url(theme/function-extensions-menu.css);
            @import url(theme/function-safeguard.css);

            @import url(theme/theme-context-menu.css);
            @import url(theme/theme-menubar.css);
            @import url(theme/theme-statuspanel.css);
            @import url(theme/theme-PIP.css);
            @import url(theme/theme-tab-audio-indicator.css);

            @import url(theme/override-linux.css);
            @import url(theme/override-mac.css);
            @import url(theme/override-styles.css);
            * {font-family: "${config.stylix.fonts.serif.name}" !important;}
          '';
        extraUserContent =
          # css
          ''
            @import url(theme/z-site-styles.css);

            @import url(theme/z-site-newtab.css);

            @import url(theme/z-site-reddit.css);

            @import url(theme/z-site-yt.css);

            /*@import url(theme/z-sites.css);*/

          '';
      };
    };
    home.file = {
      ".mozilla/firefox/schizo.default/chrome/theme/".source = "${pkgs.ff-ultima}/theme/";
      ".mozilla/native-messaging-hosts/tridactyl.json".source =
        "${pkgs.tridactyl-native}/lib/mozilla/native-messaging-hosts/tridactyl.json";
    };
    xdg = {
      configFile = {
        "tridactyl/tridactylrc".text = # vimrc
          ''
            " -*- mode: vimrc -*-
            " fix search bar and command bar behaviour
            unbind --mode=ex <Space>
            bind --mode=ex <A-Space> ex.insert_space_or_completion
            " set hint chars to prioritize comfy keys
            unset hintchars
            set hintchars eainrstgbfuoyxlcmjwpdqvh;'kz
            " disable autofocus
            set allowautofocus false
            " allow autofocus in certain sites
            seturl https://play.rust-lang.org/ allowautofocus true
            seturl https://monkeytype.com/ allowautofocus true
            seturl https://hs.${arcanum.domain}/ allowautofocus true
            seturl https://grafana.${arcanum.domain}/ allowautofocus true
            seturl https://hass.${arcanum.domain}/ allowautofocus true
            " init searchurls
            setnull searchurls.pp
            setnull searchurls.searx
            set searchurls {"sx":"https://search.${arcanum.domain}/search?q=","pp":"https://www.perplexity.ai/search?q="}
            setnull searchurls.googlelucky
            setnull searchurls.scholar
            setnull searchurls.googleuk
            setnull searchurls.bing
            setnull searchurls.duckduckgo
            setnull searchurls.yahoo
            setnull searchurls.twitter
            setnull searchurls.wikipedia
            setnull searchurls.youtube
            setnull searchurls.amazon
            setnull searchurls.amazonuk
            setnull searchurls.startpage
            setnull searchurls.github
            setnull searchurls.cnrtl
            setnull searchurls.osm
            setnull searchurls.mdn
            setnull searchurls.gentoo_wiki
            setnull searchurls.qwant
            bind <S-ArrowDown> tabnext
            bind <S-ArrowUp> tabprev
            bind <S-ArrowLeft> back
            bind <S-ArrowRight> forward
            " Comment toggler for Reddit, Hacker News and Lobste.rs
            bind ;c hint -Jc [class*="expand"],[class*="togg"],[class="comment_folder"]
            " GitHub pull request checkout command to clipboard (only works if you're a collaborator or above)
            bind yp composite js document.getElementById("clone-help-step-1").textContent.replace("git checkout -b", "git checkout -B").replace("git pull ", "git fetch ") + "git reset --hard " + document.getElementById("clone-help-step-1").textContent.split(" ")[3].replace("-","/") | yank
            " Git{Hub,Lab} git clone via SSH yank
            bind yg composite js "git clone " + document.location.href.replace(/https?:\/\//,"git@").replace("/",":").replace(/$/,".git") | clipboard yank
            " As above but execute it and open terminal in folder
            bind ,g js let uri = document.location.href.replace(/https?:\/\//,"git@").replace("/",":").replace(/$/,".git"); tri.native.run("cd ~/projects; git clone " + uri + "; cd \"$(basename \"" + uri + "\" .git)\"; st")
            " make d take you to the left (I find it much less confusing)
            bind d composite tabprev; tabclose #
            bind D tabclose
            " Make gu take you back to subreddit from comments
            bindurl reddit.com gu urlparent 4
            " " Allow Ctrl-a to select all in the commandline
            unbind --mode=ex <C-a>
            "
            " Allow Ctrl-c to copy in the commandline
            unbind --mode=ex <C-c>
            set homepages ["https://admin-apps.${arcanum.domain}/"]
            set newtab https://admin-apps.${arcanum.domain}/
            " Handy multiwindow/multitasking binds
            bind gd tabdetach
            bind gD composite tabduplicate; tabdetach
            " ge from helix scroll to end of page
            bind ge scrollto 100
            " pin tab
            bind <C-p> pin
            " mute tab
            bind <C-m> mute toggle

            " " find
            " "bind / fillcmdline find
            " "bind n findnext 1
            " "bind N findnext -1
            " "bind ,<Space> nohlsearch
            " Sane hinting mode
            " " set hintfiltermode vimperator-reflow
            "
            " Defaults to 300ms but I'm a 'move fast and close the wrong tabs' kinda chap
            set hintdelay 100
            "
            " Make Tridactyl work on more sites at the expense of some security.
            fixamo_quiet
            "
            jsb browser.webRequest.onHeadersReceived.addListener(tri.request.clobberCSP,{urls:["<all_urls>"],types:["main_frame"]},["blocking","responseHeaders"])
            " Inject Google Translate
            " This (clearly) is remotely hosted code. Google will be sent the whole
            " contents of the page you are on if you run `:translate`
            " From https://github.com/jeremiahlee/page-translator
            command translate js let googleTranslateCallback = document.createElement('script'); googleTranslateCallback.innerHTML = "function googleTranslateElementInit(){ new google.translate.TranslateElement(); }"; document.body.insertBefore(googleTranslateCallback, document.body.firstChild); let googleTranslateScript = document.createElement('script'); googleTranslateScript.charset="UTF-8"; googleTranslateScript.src = "https://translate.google.com/translate_a/element.js?cb=googleTranslateElementInit&tl=&sl=&hl="; document.body.insertBefore(googleTranslateScript, document.body.firstChild);

            colourscheme catppuccin

            " ALWAYS IGNORE ON MONKEYTYPE
            autocmd DocStart monkeytype.com mode ignore

          '';
        "tridactyl/themes/catppuccin.css".source = "${pkgs.catppuccin-tridactyl}/catppuccin.css";
      };
      mimeApps.defaultApplications = {
        "text/html" = "Schizofox.desktop";
        "x-scheme-handler/http" = "Schizofox.desktop";
        "x-scheme-handler/https" = "Schizofox.desktop";
        "x-scheme-handler/about" = "Schizofox.desktop";
        "x-scheme-handler/unknown" = "Schizofox.desktop";
      };
    };
  };
}
