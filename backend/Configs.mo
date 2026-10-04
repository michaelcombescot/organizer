module {
  // ===== TOPPING CONFIG =====
  public let toppingPeriod: Nat = 86400; // in seconds

  public let toppingThresholdIndex: Nat           = 1_000_000_000_000;
  public let toppingThresholdRegistryIndexes: Nat = 1_000_000_000_000;
  public let toppingThresholdBuckets: Nat         = 1_000_000_000_000;
  public let toppingThresholdSearch: Nat          = 1_000_000_000_000;
  public let toppingThresholdWorkerTopUp: Nat     = 1_000_000_000_000;
  public let toppingThresholdWorkerApp: Nat         = 1_000_000_000_000;

  public let toppingAmountIndex: Nat            = 500_000_000_000;
  public let toppingAmountRegistryIndexes: Nat  = 500_000_000_000;
  public let toppingAmountBuckets: Nat          = 500_000_000_000;
  public let toppingAmountSearch: Nat           = 500_000_000_000;
  public let toppingAmountWorkerTopUp: Nat     = 500_000_000_000;
  public let toppingAmountWorkerApp: Nat       = 500_000_000_000;

  public let newIndexNbCycles: Nat  = 1_000_000_000_000;
  public let newBucketNbCycles: Nat = 1_000_000_000_000;
  public let newSearchNbCycles: Nat = 1_000_000_000_000;
  public let newWorkerTopUpNbCycles: Nat = 1_000_000_000_000;
  public let newWorkerAppNbCycles: Nat   = 1_000_000_000_000;
}