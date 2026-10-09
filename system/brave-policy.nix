{ ... }:

{
  environment.etc."brave/policies/managed/policy.json".text = builtins.toJSON {
    # --- Brave-Extras aus ---
    BraveRewardsDisabled     = true;
    BraveWalletDisabled      = true;
    BraveVPNDisabled         = true;
    BraveAIChatEnabled       = false;   # Leo
    BraveNewsDisabled        = true;
    BraveTalkDisabled        = true;
    BraveSpeedreaderEnabled  = false;
    TorDisabled              = true;

    # --- Telemetrie aus ---
    BraveP3AEnabled          = false;
    BraveStatsPingEnabled    = false;
    BraveWebDiscoveryEnabled = false;
    MetricsReportingEnabled  = false;

    # --- Allgemein ---
    BrowserSignin            = 0;       # no google in Browser
    SpellcheckEnabled        = true;
    SpellcheckLanguage       = [ "de-AT" "en-US" ];

    # no Brave PW-Manager
    PasswordManagerEnabled = false;

    # --- Erweiterungen erzwingen (optional, sobald du die IDs hast) ---
    # ExtensionInstallForcelist = [
    #   "EXT_ID_1;https://clients2.google.com/service/update2/crx"
    # ];
  };
}
