export type PipelineStepId = 
  | 's3-upload'
  | 'lambda-trigger'
  | 'webp-compression'
  | 'thumbnail-generation'
  | 's3-processed-store'
  | 'metadata-indexing';

export interface PipelineStep {
  id: PipelineStepId;
  name: string;
  description: string;
  status: 'pending' | 'processing' | 'completed' | 'failed';
  durationMs?: number;
}

export interface UploadTask {
  id: string;
  file: File;
  title: string;
  format: string;
  sizeMb: number;
  tags: string;
  author: string;
  autoWebP: boolean;
  progress: number;
  status: 'queued' | 'uploading' | 'processing' | 'completed' | 'failed';
  errorMessage?: string;
  pipelineSteps: PipelineStep[];
  resultItem?: import('./media').MediaItem;
}

