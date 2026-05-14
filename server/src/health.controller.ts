import { Controller, Get } from '@nestjs/common';
// push test for my project kereo2
@Controller('health')
export class HealthController {
  @Get()
  check() {
    return { status: 'ok', timestamp: new Date().toISOString() };
  }
}
