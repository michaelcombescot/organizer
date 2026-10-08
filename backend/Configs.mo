module {
  // ===== JOB CONFIG =====
  public let JOB_MAX_CONCURRENT: Nat = 300;
  public let JOB_MAX_RETRY: Nat = 5;
  public let JOB_RETRY_DELAY: Nat = 60_000_000_000; // in nanoseconds

  // ===== TOPPING CONFIG =====
  public let TOPPING_PERIOD: Nat = 86400; // in seconds

  public let TOPPING_THRESHOLD_INDEX: Nat           = 1_000_000_000_000;
  public let TOPPING_THRESHOLD_REGISTRY_INDEXES: Nat = 1_000_000_000_000;
  public let TOPPING_THRESHOLD_BUCKETS: Nat         = 1_000_000_000_000;
  public let TOPPING_THRESHOLD_SEARCH: Nat          = 1_000_000_000_000;
  public let TOPPING_THRESHOLD_WORKER_TOP_UP: Nat     = 1_000_000_000_000;
  public let TOPPING_THRESHOLD_WORKER_APP: Nat         = 1_000_000_000_000;

  public let TOPPING_AMOUNT_INDEX: Nat            = 500_000_000_000;
  public let TOPPING_AMOUNT_REGISTRY_INDEXES: Nat  = 500_000_000_000;
  public let TOPPING_AMOUNT_BUCKETS: Nat          = 500_000_000_000;
  public let TOPPING_AMOUNT_SEARCH: Nat           = 500_000_000_000;
  public let TOPPING_AMOUNT_WORKER_TOP_UP: Nat     = 500_000_000_000;
  public let TOPPING_AMOUNT_WORKER_APP: Nat       = 500_000_000_000;

  public let NEW_INDEX_NB_CYCLES: Nat  = 1_000_000_000_000;
  public let NEW_BUCKET_NB_CYCLES: Nat = 1_000_000_000_000;
  public let NEW_SEARCH_NB_CYCLES: Nat = 1_000_000_000_000;
  public let NEW_WORKER_TOP_UP_NB_CYCLES: Nat = 1_000_000_000_000;
  public let NEW_WORKER_APP_NB_CYCLES: Nat   = 1_000_000_000_000;
}