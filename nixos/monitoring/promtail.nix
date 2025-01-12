{
  arcanum,
  ...
}:
{
  content = {
    services.promtail = {
      enable = true;
      configuration = {
        server = {
          http_listen_port = 3815;
          grpc_listen_port = 0;
        };
        positions = {
          filename = "/tmp/positions.yaml";
        };
        clients = [
          {
            url = "http://localtoast.${arcanum.internal}:3154/loki/api/v1/push";
          }
        ];
      };
    };
  };
}
