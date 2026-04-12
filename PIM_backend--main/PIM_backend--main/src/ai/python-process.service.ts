import {
  Injectable,
  Logger,
  OnModuleInit,
  OnModuleDestroy,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { spawn, ChildProcess } from 'child_process';
import { join } from 'path';
import { existsSync } from 'fs';

@Injectable()
export class PythonProcessService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(PythonProcessService.name);
  private pythonProcess: ChildProcess | null = null;
  private readonly aiServiceUrl: string;

  constructor(private readonly configService: ConfigService) {
    this.aiServiceUrl =
      this.configService.get<string>('AI_SERVICE_URL') ||
      'http://localhost:8000';
  }

  async onModuleInit() {
    await this.startPythonServer();
  }

  onModuleDestroy() {
    this.stopPythonServer();
  }

  private async startPythonServer() {
    // Resolve the path to the Python model directory
    const modelDir = this.configService.get<string>('AI_MODEL_DIR') ||
      join(process.cwd(), 'ODIN_Club_backend', 'ModeleAIpython');

    const mainFile = join(modelDir, 'main.py');

    if (!existsSync(mainFile)) {
      this.logger.warn(
        `Python AI main.py not found at ${mainFile}. Skipping auto-start.`,
      );
      return;
    }

    // Choose python executable: env var > python3 > python
    const pythonBin =
      this.configService.get<string>('PYTHON_BIN') || 'python';

    const port = new URL(this.aiServiceUrl).port || '8000';

    this.logger.log(
      `Starting Python AI service: ${pythonBin} -m uvicorn main:app --host 0.0.0.0 --port ${port}`,
    );

    this.pythonProcess = spawn(
      pythonBin,
      ['-m', 'uvicorn', 'main:app', '--host', '0.0.0.0', '--port', port],
      {
        cwd: modelDir,
        stdio: ['ignore', 'pipe', 'pipe'],
        // On Windows, we need shell: true for python to resolve correctly
        shell: process.platform === 'win32',
      },
    );

    this.pythonProcess.stdout?.on('data', (data: Buffer) => {
      const line = data.toString().trim();
      if (line) this.logger.log(`[AI-Python] ${line}`);
    });

    this.pythonProcess.stderr?.on('data', (data: Buffer) => {
      const line = data.toString().trim();
      // uvicorn writes startup info to stderr — log as LOG not ERROR
      if (line) this.logger.log(`[AI-Python] ${line}`);
    });

    this.pythonProcess.on('error', (err) => {
      this.logger.error(`Failed to start Python AI process: ${err.message}`);
      this.pythonProcess = null;
    });

    this.pythonProcess.on('exit', (code, signal) => {
      if (code !== null && code !== 0) {
        this.logger.warn(
          `Python AI process exited with code ${code} (signal: ${signal}).`,
        );
      }
      this.pythonProcess = null;
    });

    // Wait for uvicorn to be ready (poll /health or /)
    await this.waitForReady(port);
  }

  private async waitForReady(port: string, maxAttempts = 15) {
    const url = `http://localhost:${port}/`;
    for (let i = 1; i <= maxAttempts; i++) {
      await this.sleep(1000);
      try {
        // Dynamic import of node-fetch or use built-in fetch (Node 18+)
        const response = await fetch(url);
        if (response.ok) {
          this.logger.log(`Python AI service is ready on port ${port} ✓`);
          return;
        }
      } catch {
        this.logger.log(
          `Waiting for Python AI service... (attempt ${i}/${maxAttempts})`,
        );
      }
    }
    this.logger.warn(
      `Python AI service did not respond after ${maxAttempts}s. It may still be starting.`,
    );
  }

  private sleep(ms: number) {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }

  private stopPythonServer() {
    if (this.pythonProcess) {
      this.logger.log('Stopping Python AI service...');
      this.pythonProcess.kill('SIGTERM');
      this.pythonProcess = null;
    }
  }

  isRunning(): boolean {
    return this.pythonProcess !== null && !this.pythonProcess.killed;
  }
}
