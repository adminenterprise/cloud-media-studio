export type StorageClass = 'S3-Standard' | 'S3-Standard-IA' | 'Glacier' | 'Glacier-Deep-Archive';

export type MediaFormat = 'WEBP' | 'PNG' | 'JPG' | 'JPEG' | 'MP4' | 'GIF';

export type ProcessingStatus = 'READY' | 'PROCESSING' | 'PENDING' | 'FAILED' | 'ARCHIVED';

export interface ThumbnailVariant {
  target: 'mobile' | 'tablet' | 'desktop';
  width: number;
  height: number;
  url: string;
  sizeKb: number;
}

export interface MediaItem {
  id: number;
  title: string;
  format: MediaFormat;
  file_size_mb: number;
  storage_class: StorageClass;
  tags: string;
  author: string;
  thumbnail_url: string;
  original_url?: string;
  dimensions: string;
  status: ProcessingStatus;
  created_at: string;
  updated_at?: string;
  views_count?: number;
  downloads_count?: number;
  compression_ratio_pct?: number;
  thumbnails?: ThumbnailVariant[];
}

export interface MediaFilterState {
  searchQuery: string;
  typeFilter: 'all' | 'image' | 'video' | 'processed' | 'archived';
  storageClassFilter: 'all' | StorageClass;
  sortBy: 'newest' | 'oldest' | 'name' | 'size';
  viewMode: 'grid' | 'list';
}

