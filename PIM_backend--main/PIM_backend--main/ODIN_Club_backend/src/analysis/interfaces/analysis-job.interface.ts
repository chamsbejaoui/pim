export type AnalysisJobStatus = 'queued' | 'running' | 'completed' | 'failed' | 'canceled';

export interface AnalysisJobProgress {
  phase: string;
  progress: number;
  progressPercent: number;
  framesProcessed?: number;
  currentFrameIndex?: number;
  totalFrames?: number;
  fpsEffective?: number;
  playersDetected?: number;
  ballDetected?: boolean;
  trackerBackendEffective?: string;
  trackerStatus?: string;
  raw?: Record<string, unknown>;
}

export interface AnalysisJobRequestSnapshot {
  sourceType: 'videoPath' | 'videoUrl';
  requestedVideoPath: string;
  resolvedVideoPath: string;
  team1Name: string;
  team1ShirtColor: string;
  team2Name: string;
  team2ShirtColor: string;
  enableOffside: boolean;
  analysisPreset: 'balanced' | 'best';
  trackerBackend?: 'simple' | 'bytetrack';
  yoloWeights?: string;
  frameStride?: number;
  maxFrames?: number;
  goalDirections: Record<string, 'left' | 'right'>;
}

export interface AnalysisJobErrorSummary {
  message: string;
  exitCode?: number | null;
}

export interface AnalysisJobSummary {
  jobId: string;
  status: AnalysisJobStatus;
  createdAt: string;
  startedAt?: string;
  finishedAt?: string;
  outputJsonPath: string;
  resultAvailable: boolean;
  request: AnalysisJobRequestSnapshot;
  progress: AnalysisJobProgress;
  lastProgressAt?: string;
  pid?: number;
  cliSummary?: Record<string, unknown>;
  error?: AnalysisJobErrorSummary;
  logs: {
    stdoutTail: string[];
    stderrTail: string[];
  };
}

export interface AnalysisJobResultResponse {
  job: AnalysisJobSummary;
  result: Record<string, unknown>;
}

export interface AnalysisColorPresetsResponse {
  presets: string[];
}

