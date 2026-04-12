import {
  BadRequestException,
  Injectable,
  NotFoundException,
  OnModuleDestroy
} from '@nestjs/common';
import { ChildProcess, spawn } from 'child_process';
import { randomUUID } from 'crypto';
import { existsSync, mkdirSync } from 'fs';
import { access, mkdir, readFile, unlink } from 'fs/promises';
import { dirname, isAbsolute, join, resolve } from 'path';
import { CreateAnalysisJobDto } from './dto/analysis.dto';
import {
  AnalysisColorPresetsResponse,
  AnalysisJobErrorSummary,
  AnalysisJobProgress,
  AnalysisJobRequestSnapshot,
  AnalysisJobResultResponse,
  AnalysisJobStatus,
  AnalysisJobSummary
} from './interfaces/analysis-job.interface';

const COLOR_PRESETS = [
  'black',
  'blue',
  'cyan',
  'gray',
  'green',
  'navy',
  'orange',
  'pink',
  'purple',
  'red',
  'sky_blue',
  'white',
  'yellow'
] as const;

type GoalDirection = 'left' | 'right';

interface InternalAnalysisJob {
  jobId: string;
  status: AnalysisJobStatus;
  createdAt: Date;
  startedAt?: Date;
  finishedAt?: Date;
  outputJsonPath: string;
  request: AnalysisJobRequestSnapshot;
  progress: AnalysisJobProgress;
  lastProgressAt?: Date;
  pid?: number;
  cliSummary?: Record<string, unknown>;
  error?: AnalysisJobErrorSummary;
  stdoutTail: string[];
  stderrTail: string[];
  stdoutBuffer: string;
  stderrBuffer: string;
  resultAvailable: boolean;
  child?: ChildProcess;
  cancelRequested: boolean;
}

@Injectable()
export class AnalysisService implements OnModuleDestroy {
  private readonly jobs = new Map<string, InternalAnalysisJob>();
  private readonly backendRoot = process.cwd();
  private readonly workspaceRoot = this.resolveWorkspaceRoot();
  private readonly jobsRoot = join(this.backendRoot, 'analysis_jobs');
  private readonly resultsRoot = join(this.jobsRoot, 'results');

  constructor() {
    mkdirSync(this.resultsRoot, { recursive: true });
  }

  onModuleDestroy() {
    for (const job of this.jobs.values()) {
      if (job.child && job.status === 'running') {
        try {
          job.cancelRequested = true;
          job.child.kill('SIGTERM');
        } catch {
          // ignore shutdown kill errors
        }
      }
    }
  }

  getColorPresets(): AnalysisColorPresetsResponse {
    return {
      presets: [...COLOR_PRESETS]
    };
  }

  listJobs(): AnalysisJobSummary[] {
    return [...this.jobs.values()]
      .sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime())
      .map((job) => this.toSummary(job));
  }

  getJob(jobId: string): AnalysisJobSummary {
    return this.toSummary(this.requireJob(jobId));
  }

  async getResult(jobId: string): Promise<AnalysisJobResultResponse> {
    const job = this.requireJob(jobId);
    if (!job.resultAvailable || job.status !== 'completed') {
      throw new BadRequestException('Analysis result is not available yet');
    }

    try {
      const raw = await readFile(job.outputJsonPath, 'utf-8');
      const parsed = JSON.parse(raw) as Record<string, unknown>;
      return {
        job: this.toSummary(job),
        result: parsed
      };
    } catch (error) {
      throw new BadRequestException(
        `Failed to read analysis result JSON: ${error instanceof Error ? error.message : 'unknown error'}`
      );
    }
  }

  cancelJob(jobId: string): AnalysisJobSummary {
    const job = this.requireJob(jobId);
    if (job.status === 'completed' || job.status === 'failed' || job.status === 'canceled') {
      return this.toSummary(job);
    }
    job.cancelRequested = true;
    job.status = 'canceled';
    job.finishedAt = new Date();
    job.error = {
      message: 'Analysis job canceled by user'
    };
    if (job.child) {
      try {
        job.child.kill('SIGTERM');
      } catch {
        // ignore kill errors
      }
    }
    return this.toSummary(job);
  }

  async deleteJob(jobId: string): Promise<{ jobId: string; deleted: true }> {
    const job = this.requireJob(jobId);
    if (job.status === 'running' || job.status === 'queued') {
      throw new BadRequestException('Cannot delete a running analysis job. Cancel it first.');
    }

    if (job.resultAvailable && existsSync(job.outputJsonPath)) {
      try {
        await unlink(job.outputJsonPath);
      } catch {
        // best-effort cleanup only; continue removing job record
      }
    }

    this.jobs.delete(jobId);
    return { jobId, deleted: true };
  }

  async createJob(dto: CreateAnalysisJobDto): Promise<AnalysisJobSummary> {
    const request = await this.buildRequestSnapshot(dto);
    const jobId = randomUUID();
    const outputJsonPath = await this.resolveOutputJsonPath(jobId, dto.outputJsonPath);
    const args = this.buildPythonArgs(request, outputJsonPath);

    const job: InternalAnalysisJob = {
      jobId,
      status: 'queued',
      createdAt: new Date(),
      outputJsonPath,
      request,
      progress: {
        phase: 'queued',
        progress: 0,
        progressPercent: 0
      },
      stdoutTail: [],
      stderrTail: [],
      stdoutBuffer: '',
      stderrBuffer: '',
      resultAvailable: false,
      cancelRequested: false
    };

    this.jobs.set(jobId, job);
    this.pruneFinishedJobs();
    this.startPythonProcess(job, args);
    return this.toSummary(job);
  }

  private resolveWorkspaceRoot(): string {
    const candidates = [process.cwd(), resolve(process.cwd(), '..')];
    for (const candidate of candidates) {
      if (existsSync(join(candidate, 'football_video_analysis', '__main__.py'))) {
        return candidate;
      }
    }
    return process.cwd();
  }

  private async buildRequestSnapshot(dto: CreateAnalysisJobDto): Promise<AnalysisJobRequestSnapshot> {
    if (!dto.videoPath && !dto.videoUrl) {
      throw new BadRequestException('Either videoPath or videoUrl is required');
    }
    if (dto.videoPath && dto.videoUrl) {
      throw new BadRequestException('Provide only one of videoPath or videoUrl');
    }
    if (dto.team1Name.trim() === dto.team2Name.trim()) {
      throw new BadRequestException('team1Name and team2Name must be different');
    }

    const videoSource = dto.videoPath
      ? { sourceType: 'videoPath' as const, rawPath: dto.videoPath }
      : { sourceType: 'videoUrl' as const, rawPath: dto.videoUrl as string };
    const resolvedVideoPath = this.resolveVideoPath(videoSource.sourceType, videoSource.rawPath);
    try {
      await access(resolvedVideoPath);
    } catch {
      throw new BadRequestException(`Video file not found: ${resolvedVideoPath}`);
    }

    const goalDirections = this.toGoalDirectionRecord(
      dto.goalDirectionOverrides ?? [],
      dto.team1Name,
      dto.team2Name
    );

    const team1Color = this.normalizeColor(dto.team1ShirtColor);
    const team2Color = this.normalizeColor(dto.team2ShirtColor);
    if (team1Color === team2Color) {
      throw new BadRequestException('team1ShirtColor and team2ShirtColor must be different presets');
    }

    return {
      sourceType: videoSource.sourceType,
      requestedVideoPath: videoSource.rawPath,
      resolvedVideoPath,
      team1Name: dto.team1Name,
      team1ShirtColor: team1Color,
      team2Name: dto.team2Name,
      team2ShirtColor: team2Color,
      enableOffside: Boolean(dto.enableOffside),
      analysisPreset: dto.analysisPreset ?? 'best',
      trackerBackend: dto.trackerBackend,
      yoloWeights: dto.yoloWeights,
      frameStride: dto.frameStride,
      maxFrames: dto.maxFrames,
      goalDirections
    };
  }

  private normalizeColor(value: string): string {
    const normalized = value.trim().toLowerCase().replace(/[\s-]+/g, '_');
    if (!COLOR_PRESETS.includes(normalized as (typeof COLOR_PRESETS)[number])) {
      throw new BadRequestException(
        `Unsupported shirt color '${value}'. Supported presets: ${COLOR_PRESETS.join(', ')}`
      );
    }
    return normalized;
  }

  private toGoalDirectionRecord(
    overrides: Array<{ teamName: string; direction: GoalDirection }>,
    team1Name: string,
    team2Name: string
  ): Record<string, GoalDirection> {
    const validTeams = new Set([team1Name, team2Name]);
    const out: Record<string, GoalDirection> = {};
    for (const item of overrides) {
      const teamName = item.teamName.trim();
      if (!validTeams.has(teamName)) {
        throw new BadRequestException(
          `Goal direction override team '${item.teamName}' must match team1Name or team2Name`
        );
      }
      out[teamName] = item.direction;
    }
    return out;
  }

  private resolveVideoPath(sourceType: 'videoPath' | 'videoUrl', rawPath: string): string {
    if (sourceType === 'videoUrl') {
      if (!rawPath.startsWith('/uploads/')) {
        throw new BadRequestException('videoUrl must start with /uploads/');
      }
      const relative = rawPath.replace(/^\/+/, '');
      return join(this.backendRoot, relative);
    }

    if (isAbsolute(rawPath)) {
      return rawPath;
    }
    const backendCandidate = resolve(this.backendRoot, rawPath);
    if (existsSync(backendCandidate)) {
      return backendCandidate;
    }
    const workspaceCandidate = resolve(this.workspaceRoot, rawPath);
    return workspaceCandidate;
  }

  private async resolveOutputJsonPath(jobId: string, requestedPath?: string): Promise<string> {
    const outputPath = requestedPath
      ? isAbsolute(requestedPath)
        ? requestedPath
        : resolve(this.backendRoot, requestedPath)
      : join(this.resultsRoot, `${jobId}.result.json`);

    await mkdir(dirname(outputPath), { recursive: true });
    return outputPath;
  }

  private buildPythonArgs(request: AnalysisJobRequestSnapshot, outputJsonPath: string): string[] {
    const args = [
      '-m',
      'football_video_analysis',
      '--video-path',
      request.resolvedVideoPath,
      '--team-1-name',
      request.team1Name,
      '--team-1-shirt-color',
      request.team1ShirtColor,
      '--team-2-name',
      request.team2Name,
      '--team-2-shirt-color',
      request.team2ShirtColor,
      '--output-json-path',
      outputJsonPath,
      '--analysis-preset',
      request.analysisPreset,
      '--progress-json'
    ];

    if (request.enableOffside) {
      args.push('--enable-offside');
    }
    if (request.trackerBackend) {
      args.push('--tracker-backend', request.trackerBackend);
    }
    if (request.yoloWeights) {
      args.push('--yolo-weights', request.yoloWeights);
    }
    if (request.frameStride) {
      args.push('--frame-stride', String(request.frameStride));
    }
    if (request.maxFrames) {
      args.push('--max-frames', String(request.maxFrames));
    }
    for (const [teamName, direction] of Object.entries(request.goalDirections)) {
      args.push('--goal-direction', `${teamName}=${direction}`);
    }
    return args;
  }

  private startPythonProcess(job: InternalAnalysisJob, args: string[]) {
    const pythonModuleExists = existsSync(join(this.workspaceRoot, 'football_video_analysis', '__main__.py'));
    if (!pythonModuleExists) {
      job.status = 'failed';
      job.finishedAt = new Date();
      job.error = {
        message: `Python module not found in workspace root: ${this.workspaceRoot}/football_video_analysis`
      };
      return;
    }

    job.status = 'running';
    job.startedAt = new Date();
    job.progress = {
      phase: 'starting',
      progress: 0,
      progressPercent: 0
    };

    const child = spawn('python3', args, {
      cwd: this.workspaceRoot,
      env: {
        ...process.env,
        PYTHONUNBUFFERED: '1'
      },
      stdio: ['ignore', 'pipe', 'pipe']
    });
    job.child = child;
    job.pid = child.pid;

    if (!child.stdout || !child.stderr) {
      this.markFailed(job, 'Python process stdout/stderr pipes are not available');
      return;
    }

    child.stdout.setEncoding('utf8');
    child.stderr.setEncoding('utf8');

    child.stdout.on('data', (chunk: string) => {
      this.consumeOutput(job, 'stdout', chunk);
    });
    child.stderr.on('data', (chunk: string) => {
      this.consumeOutput(job, 'stderr', chunk);
    });
    child.on('error', (error) => {
      this.markFailed(job, `Failed to start Python process: ${error.message}`);
    });
    child.on('close', async (code, signal) => {
      this.flushOutputBuffers(job);
      job.child = undefined;
      job.pid = undefined;

      if (job.cancelRequested || job.status === 'canceled') {
        job.status = 'canceled';
        job.finishedAt = new Date();
        job.error = job.error ?? { message: 'Analysis job canceled by user' };
        return;
      }

      if (code === 0) {
        const exists = existsSync(job.outputJsonPath);
        job.resultAvailable = exists;
        job.status = exists ? 'completed' : 'failed';
        job.finishedAt = new Date();
        if (exists) {
          job.progress = {
            ...job.progress,
            phase: 'done',
            progress: 1,
            progressPercent: 100
          };
        } else {
          job.error = {
            message: 'Python process exited successfully but result JSON was not created',
            exitCode: code
          };
        }
        return;
      }

      this.markFailed(
        job,
        `Python analyzer exited with code ${code ?? 'null'}${signal ? ` (signal ${signal})` : ''}`,
        code
      );
    });
  }

  private consumeOutput(job: InternalAnalysisJob, stream: 'stdout' | 'stderr', chunk: string) {
    const bufferKey = stream === 'stdout' ? 'stdoutBuffer' : 'stderrBuffer';
    job[bufferKey] += chunk;

    let newlineIndex = job[bufferKey].indexOf('\n');
    while (newlineIndex >= 0) {
      const line = job[bufferKey].slice(0, newlineIndex);
      job[bufferKey] = job[bufferKey].slice(newlineIndex + 1);
      this.consumeLine(job, stream, line);
      newlineIndex = job[bufferKey].indexOf('\n');
    }
  }

  private flushOutputBuffers(job: InternalAnalysisJob) {
    if (job.stdoutBuffer.trim()) {
      this.consumeLine(job, 'stdout', job.stdoutBuffer);
    }
    if (job.stderrBuffer.trim()) {
      this.consumeLine(job, 'stderr', job.stderrBuffer);
    }
    job.stdoutBuffer = '';
    job.stderrBuffer = '';
  }

  private consumeLine(job: InternalAnalysisJob, stream: 'stdout' | 'stderr', rawLine: string) {
    const line = rawLine.trim();
    if (!line) {
      return;
    }

    const tail = stream === 'stdout' ? job.stdoutTail : job.stderrTail;
    this.pushTail(tail, line);

    if (stream !== 'stdout') {
      return;
    }

    try {
      const parsed = JSON.parse(line) as Record<string, unknown>;
      if (typeof parsed.phase === 'string') {
        const progressRaw = typeof parsed.progress === 'number' ? parsed.progress : 0;
        const progress = Math.max(0, Math.min(1, progressRaw));
        job.progress = {
          phase: parsed.phase,
          progress,
          progressPercent: Math.round(progress * 10000) / 100,
          framesProcessed:
            typeof parsed.frames_processed === 'number' ? parsed.frames_processed : undefined,
          currentFrameIndex:
            typeof parsed.current_frame_index === 'number' ? parsed.current_frame_index : undefined,
          totalFrames: typeof parsed.total_frames === 'number' ? parsed.total_frames : undefined,
          fpsEffective:
            typeof parsed.fps_effective === 'number' ? parsed.fps_effective : undefined,
          playersDetected:
            typeof parsed.players_detected === 'number' ? parsed.players_detected : undefined,
          ballDetected:
            typeof parsed.ball_detected === 'boolean' ? parsed.ball_detected : undefined,
          trackerBackendEffective:
            typeof parsed.tracker_backend_effective === 'string'
              ? parsed.tracker_backend_effective
              : undefined,
          trackerStatus:
            typeof parsed.tracker_status === 'string' ? parsed.tracker_status : undefined,
          raw: parsed
        };
        job.lastProgressAt = new Date();
        return;
      }

      if (parsed.status === 'ok') {
        job.cliSummary = parsed;
      }
    } catch {
      // non-JSON stdout line from Python/Ultralytics; preserved in stdoutTail.
    }
  }

  private pushTail(tail: string[], line: string, maxSize = 200) {
    tail.push(line);
    if (tail.length > maxSize) {
      tail.splice(0, tail.length - maxSize);
    }
  }

  private markFailed(job: InternalAnalysisJob, message: string, exitCode?: number | null) {
    if (job.status === 'canceled') {
      return;
    }
    job.status = 'failed';
    job.finishedAt = new Date();
    job.error = {
      message,
      ...(exitCode !== undefined ? { exitCode } : {})
    };
  }

  private requireJob(jobId: string): InternalAnalysisJob {
    const job = this.jobs.get(jobId);
    if (!job) {
      throw new NotFoundException(`Analysis job not found: ${jobId}`);
    }
    return job;
  }

  private toSummary(job: InternalAnalysisJob): AnalysisJobSummary {
    return {
      jobId: job.jobId,
      status: job.status,
      createdAt: job.createdAt.toISOString(),
      startedAt: job.startedAt?.toISOString(),
      finishedAt: job.finishedAt?.toISOString(),
      outputJsonPath: job.outputJsonPath,
      resultAvailable: job.resultAvailable,
      request: job.request,
      progress: job.progress,
      lastProgressAt: job.lastProgressAt?.toISOString(),
      pid: job.pid,
      cliSummary: job.cliSummary,
      error: job.error,
      logs: {
        stdoutTail: [...job.stdoutTail],
        stderrTail: [...job.stderrTail]
      }
    };
  }

  private pruneFinishedJobs(maxJobs = 100) {
    if (this.jobs.size <= maxJobs) {
      return;
    }
    const finished = [...this.jobs.values()]
      .filter((job) => ['completed', 'failed', 'canceled'].includes(job.status))
      .sort((a, b) => a.createdAt.getTime() - b.createdAt.getTime());
    while (this.jobs.size > maxJobs && finished.length > 0) {
      const victim = finished.shift();
      if (victim) {
        this.jobs.delete(victim.jobId);
      }
    }
  }
}
