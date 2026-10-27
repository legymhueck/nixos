{
  programs.firefox = {
    enable = true;

    profiles.default = {
      isDefault = true;

      settings = {
        "privacy.trackingprotection.enabled" = true;
        "privacy.trackingprotection.socialtracking.enabled" = true;
        "privacy.trackingprotection.emailtracking.enabled" = true;
        "privacy.donottrackheader.enabled" = true;

        "dom.security.https_only_mode" = true;
        "dom.security.https_only_mode_pbm" = true;

        "geo.enabled" = false;
        "browser.search.suggest.enabled" = false;
        "browser.urlbar.suggest.quicksuggest.sponsored" = false;
        "browser.urlbar.suggest.quicksuggest.nonsponsored" = false;
        "browser.tabs.closeWindowWithLastTab" = false;

        # Allow WebRTC (media.peerconnection) for browser-based video calls
        # RFP forces prefers-color-scheme to light; FPP keeps dark mode working
        "privacy.resistFingerprinting" = false;
        "privacy.fingerprintingProtection" = true;

        "sidebar.revamp" = true;
        "sidebar.verticalTabs" = true;

        "browser.startup.page" = 1;
        "browser.newtabpage.enabled" = false;
      };
    };

    policies = {
      DisableFirefoxStudies = true;
      OverrideFirstRunPage = "";
      OverridePostUpdatePage = "";
      DontCheckDefaultBrowser = true;

      Homepage = {
        URL = "about:blank";
        StartPage = "homepage";
        Locked = true;
      };

      NewTabPage = false;

      ManagedBookmarks = [
        { toplevel_name = "Schule"; }
        {
          name = "Scratch";
          url = "https://scratch.mit.edu/";
        }
        {
          name = "Microsoft 365";
          url = "https://m365.cloud.microsoft/";
        }
        {
          name = "Gymnasium Hückelhoven";
          url = "https://www.gymnasium-hueckelhoven.de/";
        }
        {
          name = "Logineon NRW LMS";
          url = "https://167642.logineonrw-lms.de/";
        }
        {
          name = "WebUntis";
          url = "https://gym-huckelhoven.webuntis.com/WebUntis/?school=gym-huckelhoven#/basic/login";
        }
        {
          name = "NixOS Packages";
          url = "https://search.nixos.org/packages";
        }
      ];

      SearchEngines = {
        Add = [
          {
            Name = "DuckDuckGo";
            URLTemplate = "https://duckduckgo.com/?q={searchTerms}";
            Method = "GET";
            IconURL = "https://duckduckgo.com/favicon.ico";
            Alias = "ddg";
            Description = "DuckDuckGo Search";
          }
        ];
        Default = "DuckDuckGo";
      };

      ExtensionSettings = {
        "uBlock0@raymondhill.net" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
        };
        "78272b6fa58f4a1abaac99321d503a20@proton.me" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/proton-pass/latest.xpi";
        };
        # German spellcheck dictionary (languagePacks only translate the UI)
        "de-DE@dictionaries.addons.mozilla.org" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/dictionary-german/latest.xpi";
        };
      };

      DisableTelemetry = true;
      DisableAccounts = true;
      PasswordManagerEnabled = false;
      AutofillAddressEnabled = false;
      AutofillCreditCardEnabled = false;
      TranslateEnabled = false;

      UserMessaging = {
        WhatsNew = false;
        ExtensionRecommendations = false;
        FeatureRecommendations = false;
        UrlbarInterventions = false;
        SkipOnboarding = true;
        MoreFromMozilla = false;
      };

      FirefoxHome = {
        Search = false;
        TopSites = false;
        SponsoredTopSites = false;
        Highlights = false;
        Stories = false;
        SponsoredStories = false;
        Locked = true;
      };
    };
  };
}
