import { StorageStatistics } from '../types/storage';
import { INITIAL_STORAGE_STATS } from './mockData';
import { request } from './api';

export const storageService = {
  async getStatistics(): Promise<StorageStatistics> {
    try {
      const stats = await request<any>('/api/stats');
      if (stats && stats.totalAssets !== undefined) {
        return {
          totalAssets: stats.totalAssets,
          totalSizeMb: stats.totalSizeMb,
          tiers: [
            {
              tierName: 'S3 Standard',
              storageClass: 'S3-Standard',
              count: stats.standardTier?.count || 0,
              sizeMb: stats.standardTier?.sizeMb || 0,
              unitPricePerGb: 0.025,
              monthlyCostUsd: parseFloat(((stats.standardTier?.sizeMb || 0) / 1024 * 0.025).toFixed(4)),
              colorHex: '#4f46e5'
            },
            {
              tierName: 'S3 Glacier Flexible',
              storageClass: 'Glacier',
              count: stats.glacierTier?.count || 0,
              sizeMb: stats.glacierTier?.sizeMb || 0,
              unitPricePerGb: 0.004,
              monthlyCostUsd: parseFloat(((stats.glacierTier?.sizeMb || 0) / 1024 * 0.004).toFixed(5)),
              colorHex: '#10b981'
            }
          ],
          lifecycleRules: INITIAL_STORAGE_STATS.lifecycleRules,
          finops: {
            budgetLimitUsd: stats.finops?.budgetLimitUsd || 200,
            currentSpentUsd: stats.finops?.currentSpentUsd || 9.82,
            projectedSpentUsd: 14.50,
            totalSavedUsd: stats.finops?.savingsFromGlacierUsd || 87.40,
            savingsRatePct: stats.glacierTier?.savingsPercent || 84,
            archivedFilesCount: stats.glacierTier?.count || 2,
            archivedVolumeMb: stats.glacierTier?.sizeMb || 13.70
          }
        };
      }
    } catch (e) {
      // fallback
    }
    return INITIAL_STORAGE_STATS;
  },

  async restoreSimulation(id: number): Promise<{ ok: boolean; message: string }> {
    return new Promise(resolve => {
      setTimeout(() => {
        resolve({
          ok: true,
          message: `Lệnh Restore S3 Glacier cho #${id} đã được gửi. Thời gian phục hồi dự kiến: 3-5 giờ (Expedited Retrieval).`
        });
      }, 800);
    });
  }
};

