import { MediaItem } from '../types/media';
import { StorageStatistics } from '../types/storage';
import { Collection } from '../types/collection';
import { UserProfile } from '../types/user';

export const INITIAL_USER: UserProfile = {
  id: 'usr-902',
  name: 'Alex Morgan',
  email: 'alex.morgan@cloudmedia.io',
  role: 'Senior Media Architect',
  team: 'Creative Marketing & DevOps',
  avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
  plan: 'Enterprise Pro',
  region: 'ap-southeast-1 (Singapore)'
};

export const INITIAL_MEDIA_ITEMS: MediaItem[] = [
  {
    id: 1,
    title: 'Brand Identity Vector Logo 2026',
    format: 'PNG',
    file_size_mb: 4.20,
    storage_class: 'S3-Standard',
    tags: 'Logo, Branding, Identity',
    author: 'Member 2 (Compute)',
    thumbnail_url: 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=500&auto=format&fit=crop&q=80',
    dimensions: '2048x2048',
    status: 'READY',
    created_at: '2026-10-15T08:00:00Z',
    views_count: 1420,
    downloads_count: 310,
    compression_ratio_pct: 0
  },
  {
    id: 2,
    title: 'Product Launch 4K Teaser Video',
    format: 'MP4',
    file_size_mb: 45.80,
    storage_class: 'S3-Standard',
    tags: 'Teaser, Video, Campaign',
    author: 'Member 4 (DevSecOps)',
    thumbnail_url: 'https://images.unsplash.com/photo-1574717024653-61fd2cf4d44d?w=500&auto=format&fit=crop&q=80',
    dimensions: '3840x2160 (4K UHD)',
    status: 'READY',
    created_at: '2026-10-20T10:30:00Z',
    views_count: 5890,
    downloads_count: 892,
    compression_ratio_pct: 0
  },
  {
    id: 3,
    title: 'Poster Banner Marketing 4K UHD',
    format: 'WEBP',
    file_size_mb: 12.50,
    storage_class: 'S3-Standard',
    tags: 'Banner, Marketing, 4K',
    author: 'Member 1 (Team Leader)',
    thumbnail_url: 'https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=500&auto=format&fit=crop&q=80',
    dimensions: '3840x2160',
    status: 'READY',
    created_at: '2026-10-25T14:15:00Z',
    views_count: 3120,
    downloads_count: 450,
    compression_ratio_pct: 84
  },
  {
    id: 4,
    title: 'Global Summit Keynote Highlights 2025',
    format: 'WEBP',
    file_size_mb: 8.10,
    storage_class: 'Glacier',
    tags: 'Archive, Event, Keynote',
    author: 'Member 3 (FinOps)',
    thumbnail_url: 'https://images.unsplash.com/photo-1511578314322-379afb476865?w=500&auto=format&fit=crop&q=80',
    dimensions: '4000x3000',
    status: 'ARCHIVED',
    created_at: '2025-08-10T09:00:00Z',
    views_count: 210,
    downloads_count: 15,
    compression_ratio_pct: 85
  },
  {
    id: 5,
    title: 'Summer Social Reel Video Campaign',
    format: 'MP4',
    file_size_mb: 28.40,
    storage_class: 'S3-Standard',
    tags: 'Reel, Social, Summer',
    author: 'Creative Marketing',
    thumbnail_url: 'https://images.unsplash.com/photo-1536240478700-b869070f9279?w=500&auto=format&fit=crop&q=80',
    dimensions: '1080x1920 (9:16)',
    status: 'READY',
    created_at: '2026-10-28T16:45:00Z',
    views_count: 4780,
    downloads_count: 630,
    compression_ratio_pct: 0
  },
  {
    id: 6,
    title: 'Q3 Financial Performance Infographic',
    format: 'WEBP',
    file_size_mb: 5.60,
    storage_class: 'Glacier',
    tags: 'Finance, Report, Infographic',
    author: 'Audit & Compliance',
    thumbnail_url: 'https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=500&auto=format&fit=crop&q=80',
    dimensions: '2400x3600',
    status: 'ARCHIVED',
    created_at: '2024-09-30T11:20:00Z',
    views_count: 120,
    downloads_count: 8,
    compression_ratio_pct: 88
  },
  {
    id: 7,
    title: 'Design System Typography & Tokens',
    format: 'PNG',
    file_size_mb: 3.10,
    storage_class: 'S3-Standard',
    tags: 'DesignSystem, Tokens, UI',
    author: 'Design Ops',
    thumbnail_url: 'https://images.unsplash.com/photo-1507238691740-187a5b1d37b8?w=500&auto=format&fit=crop&q=80',
    dimensions: '2560x1440',
    status: 'READY',
    created_at: '2026-10-30T13:00:00Z',
    views_count: 980,
    downloads_count: 215,
    compression_ratio_pct: 0
  },
  {
    id: 8,
    title: 'Architecture Blueprint Cloud Native AWS',
    format: 'WEBP',
    file_size_mb: 6.80,
    storage_class: 'S3-Standard',
    tags: 'Architecture, Diagram, AWS',
    author: 'Member 1 (Team Leader)',
    thumbnail_url: 'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=500&auto=format&fit=crop&q=80',
    dimensions: '3840x2160',
    status: 'READY',
    created_at: '2026-11-01T07:30:00Z',
    views_count: 2450,
    downloads_count: 410,
    compression_ratio_pct: 82
  }
];

export const INITIAL_STORAGE_STATS: StorageStatistics = {
  totalAssets: 8,
  totalSizeMb: 106.40,
  tiers: [
    {
      tierName: 'S3 Standard',
      storageClass: 'S3-Standard',
      count: 6,
      sizeMb: 92.70,
      unitPricePerGb: 0.025,
      monthlyCostUsd: 0.0023,
      colorHex: '#4f46e5'
    },
    {
      tierName: 'S3 Standard-IA',
      storageClass: 'S3-Standard-IA',
      count: 0,
      sizeMb: 0,
      unitPricePerGb: 0.0125,
      monthlyCostUsd: 0,
      colorHex: '#06b6d4'
    },
    {
      tierName: 'S3 Glacier Flexible',
      storageClass: 'Glacier',
      count: 2,
      sizeMb: 13.70,
      unitPricePerGb: 0.004,
      monthlyCostUsd: 0.00005,
      colorHex: '#10b981'
    },
    {
      tierName: 'S3 Glacier Deep Archive',
      storageClass: 'Glacier-Deep-Archive',
      count: 0,
      sizeMb: 0,
      unitPricePerGb: 0.00099,
      monthlyCostUsd: 0,
      colorHex: '#64748b'
    }
  ],
  lifecycleRules: [
    {
      id: 'rule-01',
      name: 'Auto-Archive to S3 Glacier after 30 days',
      sourceTier: 'S3 Standard',
      destinationTier: 'S3 Glacier Flexible',
      daysThreshold: 30,
      savingsPercentage: 84,
      status: 'ACTIVE'
    },
    {
      id: 'rule-02',
      name: 'Deep Archive Historical Audits after 90 days',
      sourceTier: 'S3 Glacier Flexible',
      destinationTier: 'S3 Glacier Deep Archive',
      daysThreshold: 90,
      savingsPercentage: 96,
      status: 'ACTIVE'
    }
  ],
  finops: {
    budgetLimitUsd: 200.00,
    currentSpentUsd: 9.82,
    projectedSpentUsd: 14.50,
    totalSavedUsd: 87.40,
    savingsRatePct: 84,
    archivedFilesCount: 2,
    archivedVolumeMb: 13.70
  }
};

export const INITIAL_COLLECTIONS: Collection[] = [
  {
    id: 'col-01',
    name: 'Brand Identity & Guidelines 2026',
    description: 'Logo vectors, color palettes, and official media kit for corporate marketing.',
    itemCount: 14,
    totalSizeMb: 52.4,
    colorTag: '#4f46e5',
    coverThumbnails: [
      'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=200&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1507238691740-187a5b1d37b8?w=200&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=200&auto=format&fit=crop&q=80'
    ],
    createdAt: '2026-10-12',
    updatedAt: '2026-10-25',
    createdBy: 'Alex Morgan'
  },
  {
    id: 'col-02',
    name: 'Q4 Product Launch Campaign',
    description: '4K Teasers, vertical reels, and social media promotional motion graphic assets.',
    itemCount: 28,
    totalSizeMb: 184.2,
    colorTag: '#06b6d4',
    coverThumbnails: [
      'https://images.unsplash.com/photo-1574717024653-61fd2cf4d44d?w=200&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1536240478700-b869070f9279?w=200&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=200&auto=format&fit=crop&q=80'
    ],
    createdAt: '2026-10-18',
    updatedAt: '2026-10-28',
    createdBy: 'Creative Marketing'
  },
  {
    id: 'col-03',
    name: 'Audited Financial & Legal Archives',
    description: 'Historical summit photos, annual infographic reports transitioned to cold storage.',
    itemCount: 9,
    totalSizeMb: 36.8,
    colorTag: '#10b981',
    coverThumbnails: [
      'https://images.unsplash.com/photo-1511578314322-379afb476865?w=200&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=200&auto=format&fit=crop&q=80'
    ],
    createdAt: '2026-09-10',
    updatedAt: '2026-10-02',
    createdBy: 'Audit Team'
  }
];

