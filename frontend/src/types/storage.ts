export interface StorageTierMetric {
  tierName: string;
  storageClass: string;
  count: number;
  sizeMb: number;
  unitPricePerGb: number;
  monthlyCostUsd: number;
  colorHex: string;
}

export interface LifecycleRule {
  id: string;
  name: string;
  sourceTier: string;
  destinationTier: string;
  daysThreshold: number;
  savingsPercentage: number;
  status: 'ACTIVE' | 'PAUSED';
}

export interface FinOpsOverview {
  budgetLimitUsd: number;
  currentSpentUsd: number;
  projectedSpentUsd: number;
  totalSavedUsd: number;
  savingsRatePct: number;
  archivedFilesCount: number;
  archivedVolumeMb: number;
}

export interface StorageStatistics {
  totalAssets: number;
  totalSizeMb: number;
  tiers: StorageTierMetric[];
  lifecycleRules: LifecycleRule[];
  finops: FinOpsOverview;
}

