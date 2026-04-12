import { Body, Controller, Delete, Get, Param, Post } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import { AnalysisService } from './analysis.service';
import { CreateAnalysisJobDto } from './dto/analysis.dto';

@ApiTags('analysis')
@Controller('analysis')
export class AnalysisController {
  constructor(private readonly analysisService: AnalysisService) {}

  @Get('color-presets')
  @ApiOperation({ summary: 'List supported shirt color presets for video analysis' })
  getColorPresets() {
    return this.analysisService.getColorPresets();
  }

  @Get('jobs')
  @ApiOperation({ summary: 'List recent analysis jobs' })
  listJobs() {
    return this.analysisService.listJobs();
  }

  @Post('jobs')
  @ApiOperation({ summary: 'Create and start a football video analysis job' })
  createJob(@Body() dto: CreateAnalysisJobDto) {
    return this.analysisService.createJob(dto);
  }

  @Get('jobs/:jobId')
  @ApiOperation({ summary: 'Get analysis job status/progress' })
  getJob(@Param('jobId') jobId: string) {
    return this.analysisService.getJob(jobId);
  }

  @Post('jobs/:jobId/cancel')
  @ApiOperation({ summary: 'Cancel a running analysis job' })
  cancelJob(@Param('jobId') jobId: string) {
    return this.analysisService.cancelJob(jobId);
  }

  @Get('jobs/:jobId/result')
  @ApiOperation({ summary: 'Fetch completed analysis result JSON' })
  getResult(@Param('jobId') jobId: string) {
    return this.analysisService.getResult(jobId);
  }

  @Delete('jobs/:jobId')
  @ApiOperation({ summary: 'Delete an analysis job and its saved result (if any)' })
  deleteJob(@Param('jobId') jobId: string) {
    return this.analysisService.deleteJob(jobId);
  }
}
