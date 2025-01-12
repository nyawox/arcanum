{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

buildGoModule rec {
  pname = "crowdsec-notification-http";
  version = "1.6.4";

  src = fetchFromGitHub {
    owner = "crowdsecurity";
    repo = "crowdsec";
    rev = "v${version}";
    hash = "sha256-U3YnLjsD+Kl/6HD+RPP0gWa4N96X5wkbdCmIrxas1I8=";
  };

  subPackages = [ "cmd/notification-http" ];

  vendorHash = "sha256-PtBVXPbLNdJyS8v8H9eRB6sTPaiseg18+eXToHvH7tw=";

  ldflags = [
    "-s"
    "-w"
  ];

  meta = {
    description = "CrowdSec - the open-source and participative security solution offering crowdsourced protection against malicious IPs and access to the most advanced real-world CTI";
    homepage = "https://github.com/crowdsecurity/crowdsec/tree/master/cmd/notification-http";
    license = lib.licenses.mit;
    mainProgram = "crowdsec-notification-http";
  };
}
