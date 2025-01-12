_: {
  content.security.tpm2 = {
    enable = true;
    pkcs11.enable = true; # /run/current-system/sw/lib/libtpm2_pkcs11.so
    tctiEnvironment.enable = true; # TPM2TOOLS_TCTI and TPM2_PKCS11_TCTI envvar
  };
}
