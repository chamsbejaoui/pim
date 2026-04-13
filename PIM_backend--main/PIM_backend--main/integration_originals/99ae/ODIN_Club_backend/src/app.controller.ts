import { Controller, Get } from '@nestjs/common';

@Controller()
export class AppController {
  @Get('health')
  health() {
    return { status: 'ok', service: 'odin_backend', timestamp: new Date().toISOString() };
  }
}
