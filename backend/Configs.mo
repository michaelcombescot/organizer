module {
    // ===== TOPPING CONFIG =====
    public let toppingThresholdIndex: Nat = 1_000_000_000_000;
    public let toppingThresholdRegistry: Nat = 1_000_000_000_000;
    public let toppingThresholdBuckets: Nat = 1_000_000_000_000;

    public let toppingAmountIndex: Nat = 500_000_000_000;
    public let toppingAmountRegistry: Nat = 500_000_000_000;
    public let toppingAmountBuckets: Nat = 500_000_000_000;

    public let toppingIntervalIndex: Nat = 60_000_000_000; // 1 minute in nanoseconds
    public let toppingIntervalRegistry: Nat = 60_000_000_000;
    public let toppingIntervalBuckets: Nat = 60_000_000_000;

    public let newBucketNbCycles: Nat = 1_000_000_000_000;
}