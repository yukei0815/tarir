self: {
  pkgs = { };

  # Variant packages are not updated by CI
  variants = {
    eden-nightly-zen4-pgo = self.eden-nightly.override {
      enablePGO = true;
      buildPreset = "zen4";
    };
  };
}
